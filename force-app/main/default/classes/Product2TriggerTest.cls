@isTest
public class Product2TriggerTest {

    @isTest
    static void simpleTest() {

        List<Warehouse__c> warehouses = new List<Warehouse__c>();
        warehouses.add(new Warehouse__c(Name = 'Warehouse A'));
        warehouses.add(new Warehouse__c(Name = 'Warehouse B'));
        insert warehouses;

  
        Product2 p = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001'
        );
        insert p;

        List<Stock__c> stockList = [
            SELECT Id, Product__c, Warehouse__c, Available_Quantity__c
            FROM Stock__c
            WHERE Product__c = :p.Id
        ];

    }
}