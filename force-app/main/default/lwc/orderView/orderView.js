import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class OrderView extends LightningElement {

    orderId;

    orderNumber = '0001';
    orderDate = '2024-01-15';

    productName = 'Industrial Widget A';
    sku = 'IW-001';
    qty = 50;
    price = 24.99;
    totalAmount = 1249.50;

    customerName = 'Acme Corp';
    email = 'contact@acme.com';
    phone = '+1 555-0101';

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef) {
            this.orderId = pageRef.state.c__orderId;
            // 👉 later yahan Apex call karoge
        }
    }
}
