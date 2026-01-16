import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NewOrderModal extends LightningModal {

     orderTypeOptions = [
        { label: 'None', value: 'None' },
        { label: 'Online', value: 'Online' },
        { label: 'Offline', value: 'Offline' }
    ];

    statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Activated', value: 'Activated' },
        { label: 'Cancelled', value: 'Cancelled' }
    ];
    
    submitForm() {
    this.template.querySelector('lightning-record-edit-form').submit();
}

    handleClose() {
        this.close(); // ✅ WORKS
    }
    submitForm() {
        this.template
            .querySelector('lightning-record-edit-form')
            .submit();
    }

    
    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Order created successfully',
                variant: 'success'
            })
        );

        // Close modal
        this.close('success');
    }
}