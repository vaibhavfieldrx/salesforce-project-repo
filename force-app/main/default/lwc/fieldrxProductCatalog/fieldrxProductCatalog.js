import { LightningElement, wire, track } from 'lwc';
import getProducts from '@salesforce/apex/FieldRx_ProductController.getProducts';

export default class FieldrxProductCatalog extends LightningElement {

    @track products = [];
    @track selectedProduct = null;

    @wire(getProducts)
    wiredProducts({ data }) {
        if (data) {
            this.products = data.map(p => {
                return { ...p, cardClass: 'product-card' };
            });
        }
    }

    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;

        this.products = this.products.map(prod => {
            return {
                ...prod,
                cardClass: prod.id === selectedId
                    ? 'product-card selected'
                    : 'product-card'
            };
        });

        this.selectedProduct = this.products.find(p => p.id === selectedId);
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