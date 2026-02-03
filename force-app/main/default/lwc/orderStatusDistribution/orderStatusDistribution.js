import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';

export default class OrderStatusDistribution extends LightningElement {
    chart;

    renderedCallback() {
        if (this.chart) return;

        loadScript(this, ChartJS)
            .then(() => {
                this.initializeChart();
            })
            .catch(error => {
                console.error(error);
            });
    }

    initializeChart() {
        const ctx = this.template.querySelector('canvas').getContext('2d');

        this.chart = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Pending', 'Processing', 'Shipped', 'Delivered'],
                datasets: [{
                    data: [32, 36, 14, 18],
                    backgroundColor: [
                        '#2563EB', // Pending - Blue
                        '#2A9D8F', // Processing - Green
                        '#F59E0B', // Shipped - Orange
                        '#A855F7'  // Delivered - Purple
                    ],
                    borderWidth: 4,
                    borderColor: '#ffffff'
                }]
            },
            options: {
                responsive: true,
                cutout: '65%',
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        enabled: true
                    }
                }
            }
        });
    }
}
