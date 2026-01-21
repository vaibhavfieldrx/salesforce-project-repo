import { LightningElement } from 'lwc';

export default class NewOrderForm extends LightningElement {

    customerId;

    handleCustomerSelect(event) {
        this.customerId = event.detail;
    }
}
