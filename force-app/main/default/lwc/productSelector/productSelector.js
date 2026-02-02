import { LightningElement, wire, track,api } from 'lwc';
import getAllProducts from '@salesforce/apex/ProductController.getAllProducts';

export default class ProductSelector extends LightningElement {

    @track products = [];
    @track selectedProducts = [];
    @track selectedRowIds = [];
   @api editProducts = [];
    @track showProductModal = false;

    @track totalDiscount = 0;
    @track finalAmount = 0;

    pageSize = 15;
    currentPage = 1;
    totalRecords = 0;

    @api
setEditProducts(orderProducts, discount) {
    if (!orderProducts?.length) return;

    this.editProducts = orderProducts;
    this.totalDiscount = discount;
    this.selectedProducts = orderProducts.map(p => ({
        id: p.productId,
        name: p.name,
        price: p.unitPrice,
        qty: p.quantity,
        subtotal: p.unitPrice * p.quantity
    }));

    // if products already loaded
    if (this.products?.length) {
        this.selectedRowIds = orderProducts
            .map(p => p.productId)
            .filter(id => this.products.some(pr => pr.id === id));
    }

    this.calculateTotal();
    this.notifyParent();
}

    columns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Code', fieldName: 'productCode' },
        { label: 'Price', fieldName: 'price', type: 'currency' }
    ];

    /* ================= APEX ================= */
    @wire(getAllProducts, {
        pageSize: '$pageSize',
        pageNumber: '$currentPage'
    })
    wiredProducts({ data }) {
        if (data) {
            this.products = data.products;
            this.totalRecords = data.totalRecords;

            if (this.editProducts?.length) {
            this.selectedRowIds = this.editProducts
                .map(p => p.productId)
                .filter(id => this.products.some(pr => pr.id === id));
        }
        }
    }

    /* ================= MODAL ================= */
    openProductModal() {
        this.selectedRowIds = this.selectedProducts.map(p => p.id);
        this.showProductModal = true;
    }

    closeProductModal() {
        this.showProductModal = false;
    }

    /* ================= PAGINATION ================= */
    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }
    get isFirstPage() {
        return this.currentPage === 1;
    }
    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    handlePrev() {
        if (!this.isFirstPage) this.currentPage--;
    }

    handleNext() {
        if (!this.isLastPage) this.currentPage++;
    }

    /* ================= TABLE SELECTION ================= */
    handleRowSelection(event) {
        const rows = event.detail.selectedRows;
        const map = new Map(this.selectedProducts.map(p => [p.id, p]));

        rows.forEach(r => {
            if (!map.has(r.id)) {
                map.set(r.id, {
                    id: r.id,
                    name: r.name,
                    price: r.price,
                    qty: 1,
                    subtotal: r.price
                });
            }
        });

        map.forEach((v, k) => {
            if (!rows.find(r => r.id === k)) {
                map.delete(k);
            }
        });

        this.selectedProducts = Array.from(map.values());
        this.selectedRowIds = rows.map(r => r.id);

        this.calculateTotal();
        this.notifyParent();
    }

    /* ================= ORDER ITEMS ================= */
    handleQtyChange(event) {
        const id = event.target.dataset.id;
        const qty = Number(event.target.value);

        this.selectedProducts = this.selectedProducts.map(p =>
            p.id === id
                ? { ...p, qty, subtotal: qty * p.price }
                : p
        );

        this.calculateTotal();
        this.notifyParent();
    }

    handleRemoveItem(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedProducts = this.selectedProducts.filter(p => p.id !== id);
        this.selectedRowIds = this.selectedProducts.map(p => p.id);

        this.calculateTotal();
        this.notifyParent();
    }

    /* ================= TOTAL DISCOUNT ================= */
    handleTotalDiscountChange(event) {
        this.totalDiscount = Number(event.target.value || 0);
        this.calculateTotal();
        this.notifyParent();
    }

    calculateTotal() {
        const grossTotal = this.selectedProducts.reduce(
            (sum, p) => sum + (p.subtotal || 0),
            0
        );

        this.finalAmount = Math.max(grossTotal - this.totalDiscount, 0);
    }


    /* ================= PARENT EVENT ================= */
    notifyParent() {
        this.dispatchEvent(new CustomEvent('productsselected', {
            detail: {
                products: this.selectedProducts.map(p => ({
                    productId: p.id,
                    quantity: p.qty,
                    unitPrice: p.price,
                    lineTotal: p.subtotal
                })),
                totalDiscount: this.totalDiscount,
                totalAmount: this.finalAmount
            }
        }));
    }
}
