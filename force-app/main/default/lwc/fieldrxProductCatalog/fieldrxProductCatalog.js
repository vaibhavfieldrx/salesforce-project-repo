import { LightningElement, wire, track } from 'lwc';
import getProducts from '@salesforce/apex/FieldRx_ProductController.getProducts';

export default class FieldrxProductCatalog extends LightningElement {

    @track products = [];

    @wire(getProducts)
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data;
        }
    }

    handleSearch(event) {
        const key = event.target.value.toLowerCase();
        const cards = this.template.querySelectorAll('.product-card');
        cards.forEach(card => {
            const name = card.querySelector('h2').innerText.toLowerCase();
            card.style.display = name.includes(key) ? 'block' : 'none';
        });
    }
}