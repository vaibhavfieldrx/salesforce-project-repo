import { LightningElement, api, wire } from 'lwc';
import getCustomerDetails from '@salesforce/apex/OrderManagementController.getCustomerDetails';

export default class CustomerInfo extends LightningElement {

    @api customerId;
    customer;

    @wire(getCustomerDetails, { customerId: '$customerId' })
    wiredCustomer({ data, error }) {
        if (data) {
            console.log("dataaa", data)
            this.customer = data;
        } else if (error) {
            console.error(error);
        }
    }


    get street() {
    return this.customer?.BillingAddress?.street || '—';
}

get city() {
    return this.customer?.BillingAddress?.city || '';
}

get country() {
    return this.customer?.BillingAddress?.country || '';
}
}
