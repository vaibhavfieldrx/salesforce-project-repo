import { LightningElement, api, wire } from 'lwc';
import getProductDetails from '@salesforce/apex/ProductController.getProductDetails';
import getProductPrice from '@salesforce/apex/ProductController.getProductPrice';

export default class ProductDetails extends LightningElement {
    @api recordId;

    product;
    price;

    @wire(getProductDetails, { productId: '$recordId' })
    wiredProduct({ data }) {
        if (data) {
            this.product = data;
        }
    }

    @wire(getProductPrice, { productId: '$recordId' })
    wiredPrice({ data }) {
        if (data !== undefined) {
            this.price = data;
        }
    }
}