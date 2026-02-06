import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getOrderDetails from '@salesforce/apex/OrderManagementController.getOrderDetails';
import submitOrderForApproval from '@salesforce/apex/OrderManagementController.submitOrderForApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 
export default class OrderView extends LightningElement {
    orderId;
 
    // ---------- ORDER DATA ----------
    @track orderNumber;
    @track orderDate;
    @track totalAmount;
    @track orderStatus;
    @track statusClass;
 
    @track customerName;
    @track email;
    @track phone;
 
    @track products = []; // order items
    @track shipping = 0;
    @track tax = 0;
 
    @track timeline = []; // <-- new timeline array
    dataLoaded = false; // <-- track if data is ready
 
    // ---------- GET ORDER ID FROM URL ----------
    @wire(CurrentPageReference)
    setPageReference(pageRef) {
        if (pageRef && pageRef.state?.c__orderId) {
            this.orderId = pageRef.state.c__orderId;
            this.fetchOrderDetails(); // <-- call method when orderId is set
        }
    }
 
    fetchOrderDetails() {
        if (!this.orderId) return;
 
        getOrderDetails({ orderId: this.orderId })
            .then((data) => {
                console.log("datadatadata", data)
                if (data) {
                    this.orderNumber = data.order.OrderNumber;
                    this.orderDate = data.order.EffectiveDate;
                    this.totalAmount = data.order.TotalAmount;
                    this.orderStatus = data.order.Status;
                    this.statusClass = this.getStatusClass(data.order.Status);
 
                    this.customerName = data.order.Account?.Name;
                    this.email = data.order?.Account?.PersonEmail;
                    this.phone = data?.order?.Account?.Phone;
 
                    this.products = data?.order?.OrderItems?.map(item => ({
                        id: item.Id,
                        name: item.Product2.Name,
                        sku: item.Product2.StockKeepingUnit,
                        qty: item.Quantity,
                        price: item.UnitPrice,
                        total: item.TotalPrice
                    })) || [];
 
                    this.shipping = data?.order?.Shipping || 0;
                    this.tax = data.Tax || 0;
 
                    // ---------- DYNAMIC TIMELINE ----------
                    this.timeline = this.getTimeline(data.order.Status);
 
                    this.dataLoaded = true; // <-- now template can render
                }
            })
            .catch((error) => {
                console.error('Error fetching order details', error);
            });
    }
 
    get grandTotal() {
        return (this.totalAmount || 0) + (this.tax || 0);
    }
 
    getStatusClass(status) {
        switch(status) {
            case 'Delivered': return 'delivered';
            case 'Approved': return 'processing';
            case 'Returned': return 'shipped';
            case 'Cancelled': return 'cancelled';
            case 'Reject': return 'rejected';
            default: return 'pending';
        }
    }
 
@track isApprovalModalOpen = false;
@track approvalComment = '';
 
// Open modal
openApprovalModal() {
    this.isApprovalModalOpen = true;
}
 
get canSubmitApproval() {
    // show button only if status is not 'Approved', 'Delivered', or 'Cancelled'
    return !['Approved', 'Delivered', 'Cancelled', 'Rejected'].includes(this.orderStatus);
}
 
// Close modal
closeApprovalModal() {
    this.isApprovalModalOpen = false;
    this.approvalComment = ''; // reset comment
}
 
// Handle comment input
handleCommentChange(event) {
    this.approvalComment = event.target.value;
}
 
// Submit approval
handleSubmitApproval() {
    if (!this.approvalComment) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Please enter a comment before submitting.',
                variant: 'error'
            })
        );
        return;
    }
 
    submitOrderForApproval({
        orderId: this.orderId,
        comment: this.approvalComment
    })
    .then(result => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: result,
                variant: 'success'
            })
        );
        this.closeApprovalModal(); // close modal after success
        this.fetchOrderDetails(); // refresh order
    })
    .catch(error => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || error.message,
                variant: 'error'
            })
        );
    });
}
 
    // ---------- TIMELINE LOGIC ----------
 getTimeline(currentStatus) {
    const steps = [
        { label: 'Draft', description: 'Order is in draft stage' },
        { label: 'Order Placed', description: 'Order has been placed by customer' },
        { label: 'Processing', description: 'Order is being prepared' },
        { label: 'Shipped', description: 'Order is on its way' },
        { label: 'Delivered', description: 'Order has been delivered' }
    ];
 
    const statusOrder = ['Draft', 'Order Placed', 'Processing', 'Shipped', 'Delivered'];
 
    const currentIndex = statusOrder.indexOf(this.mapStatusToStep(currentStatus));
 
    return steps.map((step, index) => {
        let color = 'gray';
        if (index < currentIndex) color = 'green';        // completed
        else if (index === currentIndex) color = 'orange'; // current step
        return { ...step, color };
    });
}
 
mapStatusToStep(status) {
    switch(status) {
        case 'Draft': return 'Draft';
        case 'Delivered': return 'Delivered';
        case 'Approved': return 'Processing';
        case 'Returned': return 'Shipped';
        default: return 'Order Placed';
    }
}
}
 
 