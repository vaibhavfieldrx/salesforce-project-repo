import { LightningElement, wire } from 'lwc';
import getDashboardData from '@salesforce/apex/OrderManagementController.getDashboardData';

export default class OrderList extends LightningElement {

    // ---------- STATE ----------
    orders = [];
    summaryList = [];
    revenue = 0;

    // ---------- PAGINATION ----------
    pageSize = 7;
    currentPage = 1;
    totalOrders = 0;

    // ---------- APEX ----------
    @wire(getDashboardData, {
        pageSize: '$pageSize',
        pageNumber: '$currentPage'
    })
    wiredData({ data, error }) {
        if (data) {
            this.revenue = data.revenue;
            this.totalOrders = data.totalOrders;

            // Orders mapping
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
            this.summaryList = Object.keys(data.summary || {}).map(key => ({
                label: key,
                count: data.summary[key],
                iconName: this.getSummaryIcon(key),
                iconClass: this.getIconClass(key),
                wrapperClass: `icon-wrapper ${this.getIconClass(key)}`
            }));
        } else if (error) {
            console.error('Dashboard Error', error);
        }
    }

    // ---------- PAGINATION HELPERS ----------
    get totalPages() {
        return Math.ceil(this.totalOrders / this.pageSize);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    nextPage() {
        if (!this.isLastPage) {
            this.currentPage++;
        }
    }

    prevPage() {
        if (!this.isFirstPage) {
            this.currentPage--;
        }
    }

    // ---------- UI HELPERS ----------
    getStatusClass(status) {
        if (status === 'Delivered') return 'badge delivered';
        if (status === 'Approved') return 'badge processing';
        if (status === 'Returned') return 'badge shipped';
        if (status === 'Cancelled') return 'badge cancelled';
        if (status === 'Reject') return 'badge rejected';
        return 'badge pending';
    }

    getSummaryIcon() {
        return 'utility:event';
    }

    getIconClass(status) {
        if (status === 'Delivered') return 'green-icon';
        if (status === 'Approved') return 'orange-icon';
        if (status === 'Returned') return 'blue-icon';
        if (status === 'Cancelled') return 'red-icon';
        if (status === 'Reject') return 'yellow-icon';
        return 'gray-icon';
    }
}
