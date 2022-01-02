public with sharing class OrderItemHelper {
    public OrderItemHelper() {}

    public static void checkError(List<OrderItem> orderItemList){
        for(OrderItem ordItem: orderItemList){
            if (ordItem.Quantity <= 0){
                ordItem.addError(Label.orderItemQuantityError);
            }else if(ordItem.UnitPrice <= 0){
                ordItem.addError(Label.OrderItemPriceError);
            }
        }
    }

    public static List<OrderItem> calcPrice(List<OrderItem> orderItemList){
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        for(OrderItem orderItem : orderItemList){
            orderIdSet.add(orderItem.OrderId);
            productIdSet.add(orderItem.product2Id);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, Account.AccountGroup__c, DistributionCenter__c, DistributionCenter__r.State__c
            FROM Order
            WHERE Id IN :orderIdSet
        ]);

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, ProductHierarchy__c
            FROM Product2
            WHERE Id IN :productIdSet
        ]);

        Map<OrderItem, PriceMargin__c> orderItemToMargin = searchMargin(orderItemList, orderMap, productMap);

        for(OrderItem orderItem : orderItemToMargin.keySet()){
            PriceMargin__c priceMargin = orderItemToMargin.get(orderItem);

            if(priceMargin != null){
                orderItem.PriceMargin__c = priceMargin.id;
                orderItem.Price__c = orderItem.ListPrice - (orderItem.ListPrice * (priceMargin.Margin__c/100));
            }
        }

        return new list<OrderItem>(OrderItemToMargin.keySet());
    }

    public static Map<OrderItem, PriceMargin__c> searchMargin(List<OrderItem> orderItemList, Map<Id, Order> orderMap, Map<Id, Product2> productMap){
        List<Id> productIdSet      = new List<Id>();
        List<Id> hierarchyIdSet    = new List<Id>();
        List<Id> accountIdSet      = new List<Id>();
        List<Id> groupIdSet        = new List<Id>();
        List<Id> distributionIdSet = new List<Id>();
        List<Id> stateIdSet        = new List<Id>();

        for(Product2 product : productMap.values()){
            productIdSet.add(product.Id);
            hierarchyIdSet.add(product.productHierarchy__c);
        }

        for(Order order : orderMap.values()){
            accountIdSet.add(order.AccountId);
            groupIdSet.add(order.Account.AccountGroup__c);
            distributionIdSet.add(order.DistributionCenter__c);
            stateIdSet.add(order.DistributionCenter__r.State__c);
        }
        

        List<PriceMargin__c> priceMarginList = [
            SELECT Id, Product__c, ProductHierarchy__c, Account__c, AccountGroup__c, DistributionCenter__c, State__c, Margin__c, Score__c
            FROM PriceMargin__c
            WHERE 
            (Product__c              IN :productIdSet        OR Product__c = null)            AND 
            (ProductHierarchy__c     IN :hierarchyIdSet      OR ProductHierarchy__c = null)   AND
            (Account__c              IN :AccountIdSet        OR Account__c = null)            AND
            (AccountGroup__c         IN :GroupIdSet          OR AccountGroup__c = null)       AND
            (DistributionCenter__c   IN :DistributionIdSet   OR DistributionCenter__c = null) AND
            (State__c                IN :StateIdSet          OR State__c = null)
            ORDER BY Score__c
        ];

        Map<OrderItem, PriceMargin__c> orderItemToMargin = new Map<OrderItem, PriceMargin__c>();

        for(OrderItem orderItem: orderItemList){
            orderItemToMargin.put(orderItem, null);

            for(PriceMargin__c margin : priceMarginList){
                if(matchMargin(margin, orderItem, orderMap, productMap)){
                    orderItemToMargin.put(orderItem, margin);
                    break;
                }
            }
            
        }

        return orderItemToMargin;
    }
    public static Boolean matchMargin(PriceMargin__c margin, OrderItem orderItem,  Map<Id, Order> orderMap, Map<Id, Product2> productMap){
        return
        (String.isBlank(margin.Product__c)            || margin.Product__c            == orderItem.product2Id) &&
        (String.isBlank(margin.ProductHierarchy__c)   || margin.ProductHierarchy__c   == productMap.get(orderItem.product2Id).ProductHierarchy__c) &&
        (String.isBlank(margin.Account__c)            || margin.Account__c            == orderMap.get(orderItem.OrderId).AccountId) &&
        (String.isBlank(margin.AccountGroup__c)       || margin.AccountGroup__c       == orderMap.get(orderItem.OrderId).Account.AccountGroup__c) &&
        (String.isBlank(margin.DistributionCenter__c) || margin.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c) &&
        (String.isBlank(margin.State__c)              || margin.State__c              == orderMap.get(orderItem.OrderId).DistributionCenter__r.State__c); 

    }
}
