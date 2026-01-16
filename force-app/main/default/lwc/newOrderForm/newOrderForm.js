import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

 
export default class NewOrderForm extends LightningElement {
 
     submitForm() {
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Order created successfully',
                variant: 'success'
            })
        );
        this.close('success');
    }
}