import { LightningElement, track, wire } from 'lwc';
import getWarehouses from '@salesforce/apex/OrderManagementController.getWarehouses';

export default class OrderAddressAndWarehouse extends LightningElement {

    // ---------- ADDRESS ----------
     countryOptions = [
        { label: 'India', value: 'IN' },
        { label: 'United States', value: 'US' },
        { label: 'United Kingdom', value: 'UK' },
        { label: 'Australia', value: 'AU' },
        { label: 'Canada', value: 'CA' }
    ];

    @track billing = {
        country: 'IN'
    };

    @track shipping = {
        country: 'IN'
    };

    // ---------- WAREHOUSE ----------
    warehouseOptions = [];
    selectedWarehouseId;

    // ---------- APEX ----------
    @wire(getWarehouses)
    wiredWarehouses({ data, error }) {
        if (data) {
            this.warehouseOptions = data.map(w => ({
                label: w.Name,
                value: w.Id
            }));
        } else if (error) {
            console.error('Warehouse load error', error);
        }
    }

    handleWarehouseChange(event) {
        this.selectedWarehouseId = event.detail.value;
    }
 handleAddressChange(event) {
        const type = event.target.dataset.type;   // billing / shipping
        const field = event.target.dataset.field;
        const value = event.detail?.value || event.target.value;

        this[type][field] = value;
    }

    // expose to parent (Order Page)
    get orderPayload() {
        return {
            billingAddress: this.billing,
            shippingAddress: this.shipping,
            warehouseId: this.selectedWarehouseId
        };
    }
}
