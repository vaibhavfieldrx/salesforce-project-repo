import { LightningElement, wire } from 'lwc';
import getRecentOrders from '@salesforce/apex/RecentOrdersController.getRecentOrders';

export default class RecentOrders extends LightningElement {
    orders = [];

    @wire(getRecentOrders)
    wiredOrders({ data, error }) {
        if (data) {
            this.orders = data.map(order => {

                // If status is empty → make it Pending
                const statusValue = order.Status__c 
                    ? order.Status__c 
                    : 'Pending';

                // Convert status for CSS class (remove spaces + lowercase)
                const statusKey = statusValue
                    .toLowerCase()
                    .replace(/\s+/g, '');

                return {
                    id: order.Id,
                    orderId: order.Name,
                    company: order.Account__r?.Name || 'N/A',
                    amount: order.Amount__c,

                    // Format amount properly
                    formattedAmount: order.Amount__c
                        ? `₹${Number(order.Amount__c).toLocaleString('en-IN')}`
                        : '₹0',

                    status: statusValue,

                    // Final class for badge
                    statusClass: `status ${statusKey}`
                };
            });
        }
        else if (error) {
            console.error('Error fetching orders:', error);
        }
    }
}
