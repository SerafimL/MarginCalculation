public with sharing class OrderHelper {
    public OrderHelper() {}

    public static List<OrderItem> checkRecalcItens(Map<Id, Order> oldOrderMap, Map<Id, Order> newOrderMap){
        Set<Id> orderIdSet = new Set<Id>();
        
        for(Order newOrder : newOrderMap.values()){
            Order oldOrder = oldOrderMap.get(newOrder.Id);

            if(newOrder.DistributionCenter__c != oldOrder.DistributionCenter__c){
                orderIdSet.add(newOrder.id);
            }
        }

        list<orderItem> OrderItemList = [
            SELECT Id, Product2Id, OrderId
            FROM OrderItem
            WHERE OrderId IN :orderIdSet
        ];

        return OrderItemHelper.calcPrice(OrderItemList);
    }
}
