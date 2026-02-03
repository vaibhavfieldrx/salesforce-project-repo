import { LightningElement, wire } from 'lwc';
import getRecentOrders from '@salesforce/apex/RecentOrdersController.getRecentOrders';

export default class RecentOrders extends LightningElement {
    orders = [];

    @wire(getRecentOrders)
    wiredOrders({ data }) {
        if (data) {
            this.orders = data.map(order => {
                const status = order.Status__c ? order.Status__c.toLowerCase() : '';
                return {
                    id: order.Id,
                    orderId: order.Name,
                    company: order.Account__r?.Name,
                    amount: order.Amount__c,
                    status: order.Status__c,
                    statusClass: `status ${status}`   // ✅ FIX HERE
                };
            });
        }
    }
}
