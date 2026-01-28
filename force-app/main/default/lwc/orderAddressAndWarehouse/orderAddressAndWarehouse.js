import { LightningElement, track, wire } from 'lwc';
import getWarehouses from '@salesforce/apex/OrderManagementController.getWarehouses';

export default class OrderAddressAndWarehouse extends LightningElement {

    // ---------- ADDRESS ----------
     countryOptions = [
        { label: 'India', value: 'India' },
        { label: 'United States', value: 'United States' },
        { label: 'United Kingdom', value: 'United Kingdom' },
        { label: 'Australia', value: 'Australia' },
        { label: 'Canada', value: 'Canada' }
    ];

    @track billing = {
        country: 'India'
    };

    @track shipping = {
        country: 'India'
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
    this.notifyParent();
}

handleAddressChange(event) {
    const type = event.target.dataset.type;
    const field = event.target.dataset.field;
    const value = event.detail?.value || event.target.value;

    this[type] = {
        ...this[type],
        [field]: value
    };

    this.notifyParent();
}

notifyParent() {
    console.log('🚀 notifyParent fired', {
        billing: this.billing,
        shipping: this.shipping,
        warehouseId: this.selectedWarehouseId
    });

    this.dispatchEvent(
        new CustomEvent('addresschange', {
            detail: {
                billingAddress: { ...this.billing },
                shippingAddress: { ...this.shipping },
                warehouseId: this.selectedWarehouseId || null
            },
            bubbles: true,
            composed: true
        })
    );
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
