import { LightningElement, wire } from 'lwc';
import getCustomers from '@salesforce/apex/OrderManagementController.getCustomers';

export default class CustomerSelector extends LightningElement {

    options = [];

    @wire(getCustomers)
    wiredCustomers({ data }) {
        if (data) {
            this.options = data.map(c => ({
                label: c.Name,
                value: c.Id
            }));
        }
    }

    handleChange(event) {
        this.dispatchEvent(
            new CustomEvent('customerselect', {
                detail: event.detail.value
            })
        );
    }
}
