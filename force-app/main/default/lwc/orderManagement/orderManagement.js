import { LightningElement, wire } from 'lwc';
import getDashboardData from '@salesforce/apex/OrderManagementController.getDashboardData';
import { NavigationMixin } from 'lightning/navigation';


export default class OrderManagement extends NavigationMixin(LightningElement) {

    // ---------- STATE ----------
    orders = [];
    summaryList = [];
    revenue = 0;

    // ---------- PAGINATION ----------
    pageSize = 7;
    currentPage = 1;
    totalOrders = 0;

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
        pageNumber: '$currentPage'
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
        } else if (error) {
            console.error(error);
        }
    }

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

    getStatusClass(status) {
        if (status === 'Delivered') return 'badge delivered';
        if (status === 'Approved') return 'badge processing';
        if (status === 'Returned') return 'badge shipped';
        if (status === 'Cancelled') return 'badge cancelled';
        if (status === 'Reject') return 'badge rejected';
        return 'badge pending';
    }
}
