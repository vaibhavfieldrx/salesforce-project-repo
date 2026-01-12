import getDashboardData from '@salesforce/apex/OrderManagementController.getDashboardData';
import { LightningElement, wire, track } from 'lwc';

export default class OrderList extends LightningElement {
   @track orders = [];
    @track summaryList = [];
    revenue = 0;

    @wire(getDashboardData)
    wiredData({ data, error }) {
        if (data) {
            this.revenue = data.revenue;

            // Orders with UI-safe fields
            this.orders = data.orders.map(o => ({
                id: o.Id,
                number: o.OrderNumber,
                customer: o.Account?.Name,
                date: o.EffectiveDate,
                amount: o.TotalAmount,
                status: o.Status,
                statusClass: this.getStatusClass(o.Status)
            }));

            // Summary cards
            this.summaryList = Object.keys(data.summary).map(key => ({
                label: key,
                count: data.summary[key],
                iconClass: this.getSummaryIcon(key)
            }));
        }
    }

    getStatusClass(status) {
        return status === 'Delivered' ? 'badge delivered'
            : status === 'Processing' ? 'badge processing'
            : status === 'Shipped' ? 'badge shipped'
            : 'badge pending';
    }

    getSummaryIcon(status) {
        return status === 'Delivered' ? 'icon green'
            : status === 'Processing' ? 'icon orange'
            : status === 'Shipped' ? 'icon blue'
            : 'icon gray';
    }
}
