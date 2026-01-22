import { LightningElement, wire } from 'lwc';
import getDashboardData from '@salesforce/apex/OrderManagementController.getDashboardData';
import { NavigationMixin } from 'lightning/navigation';


export default class OrderManagement extends NavigationMixin(LightningElement) {

    // ---------- STATE ----------
    orders = [];
    summaryList = [];
    revenue = 0;

    // ---------- PAGINATION ----------
    pageSize = 10;
    currentPage = 1;
    totalOrders = 0;

    // ---------- SEARCH & FILTER ----------
    searchKey = '';
    selectedStatus = ''; // All

    // ---------- APEX ----------
    openNewOrderModal() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
             attributes: {
                url: '/createorder'
            }
        });
    }

    @wire(getDashboardData, {
        pageSize: '$pageSize',
        pageNumber: '$currentPage',
        searchKey: '$searchKey',
        status: '$selectedStatus'
    })
    wiredData({ data, error }) {
        if (data) {
            this.revenue = data.revenue;
            this.totalOrders = data.totalOrders;

            this.orders = data.orders.map(o => ({
                id: o.Id,
                number: o.OrderNumber,
                customer: o.Account?.Name,
                date: o.EffectiveDate,
                amount: o.TotalAmount,
                status: o.Status,
                statusClass: this.getStatusClass(o.Status)
            }));

            this.summaryList = Object.keys(data.summary || {}).map(key => ({
                label: key,
                count: data.summary[key],
                iconName: 'utility:event',
                wrapperClass: `icon-wrapper ${this.getIconClass(key)}`
            }));
        } else if (error) {
            console.error(error);
        }
    }

    // ---------- SEARCH ----------
    handleSearch(event) {
        this.searchKey = event.target.value;
        this.currentPage = 1;
    }

    // ---------- STATUS FILTER ----------
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.currentPage = 1;
    }

    // ---------- PAGINATION ----------
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
        if (!this.isLastPage) this.currentPage++;
    }

    prevPage() {
        if (!this.isFirstPage) this.currentPage--;
    }

    // ---------- STATUS OPTIONS ----------
    get statusOptions() {
        return [
            { label: 'All', value: '' },
            { label: 'Delivered', value: 'Delivered' },
            { label: 'Approved', value: 'Approved' },
            { label: 'Returned', value: 'Returned' },
            { label: 'Cancelled', value: 'Cancelled' },
            { label: 'Rejected', value: 'Reject' }
        ];
    }

    getStatusClass(status) {
        if (status === 'Delivered') return 'badge delivered';
        if (status === 'Approved') return 'badge processing';
        if (status === 'Returned') return 'badge shipped';
        if (status === 'Cancelled') return 'badge cancelled';
        if (status === 'Reject') return 'badge rejected';
        return 'badge pending';
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
