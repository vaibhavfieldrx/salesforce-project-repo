import { LightningElement, wire } from 'lwc';
import getOrdersForSMApproval from
    '@salesforce/apex/OrderManagementController.getOrdersForSMApproval';
import approveOrder from
    '@salesforce/apex/OrderManagementController.approveOrder';
import rejectOrder from
    '@salesforce/apex/OrderManagementController.rejectOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApprovalInbox extends LightningElement {

    orders = [];

    @wire(getOrdersForSMApproval)
    wiredOrders({ data }) {
        if (data) {
            this.orders = data;
        }
    }
    

    // async approve(event) {
    //     const orderId = event.target.dataset.id;
    //     await approveOrder({ orderId });
    //     this.removeOrder(orderId);
    //     this.toast('Success', 'Order approved', 'success');
    // }
    
    async approve(event) {
    const workItemId = event.target.dataset.workitemid;
        console.log("workItemId", workItemId)
    if (!workItemId) {
        this.toast('Error', 'WorkItemId missing', 'error');
        return;
    }

    await approveOrder({
        workItemId: workItemId,
        comment: this.comment   // optional
    });

    await refreshApex(this.pendingApprovals);

    this.toast('Success', 'Order approved', 'success');
}

    async reject(event) {
        const orderId = event.target.dataset.id;
        await rejectOrder({ orderId });
        this.removeOrder(orderId);
        this.toast('Rejected', 'Order rejected', 'warning');
    }

    removeOrder(orderId) {
        this.orders = this.orders.filter(o => o.Id !== orderId);
    }

    toast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}
