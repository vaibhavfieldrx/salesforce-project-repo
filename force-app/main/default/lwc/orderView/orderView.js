import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getOrderDetails from '@salesforce/apex/OrderManagementController.getOrderDetails';

export default class OrderView extends LightningElement {

    orderId;

    // ---------- ORDER DATA ----------
    orderNumber;
    orderDate;
    totalAmount;

    customerName;
    email;
    phone;

    products = []; // if you want order items later

    // ---------- GET ORDER ID FROM URL ----------
    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef && pageRef.state?.c__orderId) {
            this.orderId = pageRef.state.c__orderId;
        }
    }

    // ---------- FETCH ORDER DETAILS ----------
    @wire(getOrderDetails, { orderId: '$orderId' })
    wiredOrder({ data, error }) {
        if (data) {
            this.orderNumber = data.OrderNumber;
            this.orderDate = data.EffectiveDate;
            this.totalAmount = data.TotalAmount;

            this.customerName = data.Account?.Name;
            this.email = data.Account?.PersonEmail;
            this.phone = data.Account?.Phone;

            // OPTIONAL: Order Items
            this.products = data.OrderItems?.map(item => ({
                id: item.Id,
                name: item.Product2.Name,
                sku: item.Product2.StockKeepingUnit,
                qty: item.Quantity,
                price: item.UnitPrice,
                total: item.TotalPrice
            })) || [];

        } else if (error) {
            console.error('Error loading order', error);
        }
    }
}
