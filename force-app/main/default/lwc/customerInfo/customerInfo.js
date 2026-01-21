import { LightningElement, api, wire } from 'lwc';
import getCustomerDetails from '@salesforce/apex/OrderManagementController.getCustomerDetails';

export default class CustomerInfo extends LightningElement {

    @api customerId;
    customer = {};

    @wire(getCustomerDetails, { customerId: '$customerId' })
    wiredCustomer({ data }) {
        if (data) this.customer = data;
    }
}
