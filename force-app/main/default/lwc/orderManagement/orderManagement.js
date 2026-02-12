import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getDashboardData from '@salesforce/apex/OrderManagementController.getDashboardData';
import deleteOrder from '@salesforce/apex/OrderManagementController.deleteOrder';
import getUserDepartment from '@salesforce/apex/UserContactController.getUserDepartment';

export default class OrderManagement extends NavigationMixin(LightningElement) {

    // ================= STATE =================
    orders = [];
    summaryList = [];
    revenue = 0;

    // ================= PAGINATION =================
    pageSize = 10;
    currentPage = 1;
    totalOrders = 0;

    // ================= FILTERS =================
    searchKey = '';
    selectedStatus = '';

    // ================= NAVIGATION =================


    @track userDepartment;

@wire(getUserDepartment)
wiredUserDepartment({ data, error }) {
    if (data) {
        this.userDepartment = data;
    } else if (error) {
        console.error(error);
    }
}


get showApprovalInbox() {
    return this.userDepartment === 'SM' || this.userDepartment === 'Admin';
}

    openNewOrderModal() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: '/createorder' }
        });
    }

    // ================= ACTION HANDLER =================
    async handleAction(event) {
        const [action, orderId] = event.detail.value.split(':');

        if (action === 'view') {
            this.navigateToViewOrder(orderId);
        } 
        else if (action === 'edit') {
            this.navigateToEditOrder(orderId);
        } 
        else if (action === 'delete') {
            await this.confirmDelete(orderId);
        }
    }

    // ================= CONFIRM DELETE =================
    async confirmDelete(orderId) {
        const result = await LightningConfirm.open({
            label: 'Delete Order',
            message: 'Are you sure you want to delete this order?',
            theme: 'warning'
        });

        if (result) {
            this.deleteOrderRecord(orderId);
        }
    }

    async deleteOrderRecord(orderId) {
        try {
            await deleteOrder({ orderId });

            this.orders = this.orders.filter(o => o.id !== orderId);
            this.totalOrders--;

            this.showToast('Success', 'Order deleted successfully', 'success');
        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || 'Failed to delete order',
                'error'
            );
        }
    }

    // ================= NAVIGATIONS =================
    navigateToEditOrder(orderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/createorder?c__mode=edit&c__orderId=${orderId}`
            }
        });
    }

    navigateToViewOrder(orderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/order-view?c__orderId=${orderId}`
            }
        });
    }

    // ================= APEX DATA =================
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
                statusClass: this.getStatusClass(o.Status),
                isDraft: o.Status === 'Draft',
                view: `view:${o.Id}`,
                edit: `edit:${o.Id}`,
                delete: `delete:${o.Id}`
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

    // ================= SEARCH & FILTER =================
    handleSearch(event) {
        this.searchKey = event.target.value;
        this.currentPage = 1;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.currentPage = 1;
    }

    // ================= PAGINATION =================
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

    // ================= HELPERS =================
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

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}
