import { LightningElement, wire, track } from 'lwc';
import getAllProducts from '@salesforce/apex/FieldRx_ProductController.getAllProducts';
import ProductImage from '@salesforce/resourceUrl/ProductImage';

export default class FieldrxProductCatalog extends LightningElement {

    @track products = [];
    @track allProducts = [];
    @track selectedProduct;
    categories = [];

    @wire(getAllProducts)
    wiredProducts({ data, error }) {
        if (data) {

            this.allProducts = data.map(prod => {
    return {
        id: prod.id,
        name: prod.name,
        code: prod.code,
        category: prod.category ? prod.category.trim() : 'Uncategorized',
        price: prod.price,
        status: prod.isActive ? 'Active' : 'Inactive',
        cardClass: 'product-card',
        imageUrl: ProductImage
    };
});

            this.products = [...this.allProducts];

            // Build category list
            const cats = new Set();
            this.allProducts.forEach(p => {
                if(p.category) cats.add(p.category);
            });
            this.categories = [...cats];

        } else if (error) {
            console.error(error);
        }
    }

    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;

        this.products = this.products.map(prod => {
            return {
                ...prod,
                cardClass: prod.id === selectedId ? 'product-card selected' : 'product-card'
            };
        });

        this.selectedProduct = this.products.find(p => p.id === selectedId);
    }

    handleSearch(event) {
    const key = event.target.value ? event.target.value.toLowerCase() : '';

    this.products = this.allProducts.filter(prod => {
        const name = prod.name ? prod.name.toLowerCase() : '';
        const code = prod.code ? prod.code.toLowerCase() : '';
        return name.includes(key) || code.includes(key);
    });
}
handleCategoryClick(event) {
    const selectedCat = event.target.textContent.trim();

    // Highlight active category
    this.template.querySelectorAll('.category-list li')
        .forEach(el => el.classList.remove('active'));
    event.target.classList.add('active');

    // Filter products
    if (selectedCat === 'All Categories') {
        this.products = [...this.allProducts];
    } else {
        this.products = this.allProducts.filter(
            prod => prod.category === selectedCat
        );
    }

    // Reset selected product
    this.selectedProduct = null;
}
}