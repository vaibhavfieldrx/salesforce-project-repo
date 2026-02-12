import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class CustomAlert extends LightningModal {
    @api title;
    @api message;
    handleClose() {
        this.close();
    }
}
