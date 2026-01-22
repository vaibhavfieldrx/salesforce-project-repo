import { LightningElement, api, wire } from 'lwc';
import getCustomerDetails from '@salesforce/apex/OrderManagementController.getCustomerDetails';

export default class CustomerInfo extends LightningElement {

    @api customerId;
    customer;

    @wire(getCustomerDetails, { customerId: '$customerId' })
    wiredCustomer({ data, error }) {
        if (data) {
            this.customer = data;
        } else if (error) {
            console.error(error);
        }
    }
}
