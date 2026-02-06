import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getOrderDetails from '@salesforce/apex/OrderDetailsController.getOrderDetails';

export default class OrderView extends LightningElement {

    orderId;

    // Order Data
    orderNumber;
    orderDate;
    status;
    totalAmount = 0;

    // Customer Info
    customerName;
    email;
    phone;

    // Order Items
    products = [];

    // ---------- GET ORDER ID FROM URL ----------
    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef?.state?.c__orderId) {
            this.orderId = pageRef.state.c__orderId;
        }
    }

    // ---------- FETCH ORDER DETAILS ----------
    @wire(getOrderDetails, { orderId: '$orderId' })
    wiredOrder({ data, error }) {
        if (data) {
            const order = data.order;
            const items = data.orderItems;

            // Order info
            this.orderNumber = order.OrderNumber;
            this.orderDate = order.EffectiveDate;
            this.status = order.Status;
            this.totalAmount = order.TotalAmount;

            // Customer info (via AccountId)
            this.customerName = order.Account?.Name;
            this.email = order.Account?.PersonEmail;
            this.phone = order.Account?.Phone;

            // Products
            this.products = items.map(item => ({
                id: item.Id,
                name: item.Product2?.Name,
                sku: item.Product2?.StockKeepingUnit,
                qty: item.Quantity,
                price: item.UnitPrice,
                total: item.TotalPrice
            }));
        } else if (error) {
            console.error('Error loading order', error);
        }
    }

    // ---------- UI HELPERS ----------
    get formattedOrderDate() {
        return this.orderDate ? new Date(this.orderDate).toLocaleDateString() : '';
    }

    get statusClass() {
        switch (this.status) {
            case 'Delivered': return 'status delivered';
            case 'Shipped': return 'status shipped';
            case 'Processing': return 'status processing';
            default: return 'status';
        }
    }

    get hasProducts() {
        return this.products.length > 0;
    }

    get timelineClasses() {
        const status = this.status || '';
        return {
            orderPlaced: 'blue',
            processing: status === 'Processing' ? 'orange' : 'blue',
            shipped: status === 'Shipped' || status === 'Delivered' ? 'blue' : 'gray',
            delivered: status === 'Delivered' ? 'green' : 'gray'
        };
    }

    // ---------- BACK BUTTON ----------
    handleBack() {
        window.history.back();
    }
}
