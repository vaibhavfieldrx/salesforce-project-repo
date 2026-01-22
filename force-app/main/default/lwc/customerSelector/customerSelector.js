import { LightningElement, wire } from 'lwc';
import getCustomers from '@salesforce/apex/OrderManagementController.getCustomers';

export default class CustomerSelector extends LightningElement {

    options = [];

    @wire(getCustomers)
    wiredCustomers({ data, error }) {
        if (data) {
            this.options = data.map(c => ({
                label: c.Name,
                value: c.Id
            }));
        } else if (error) {
            console.error(error);
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
