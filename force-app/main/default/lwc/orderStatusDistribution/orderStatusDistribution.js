import { LightningElement, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';
import getOrderStatusData from '@salesforce/apex/OrderStatusChartController.getOrderStatusData';

export default class OrderStatusDistribution extends LightningElement {
    chart;
    chartJsLoaded = false;
    dataLoaded = false;
    wiredResult;

    @wire(getOrderStatusData)
    wiredOrderData(result) {
        this.wiredResult = result;
        if (result.data) {
            this.dataLoaded = true;
            this.renderChart();
        }
    }

    renderedCallback() {
        if (this.chartJsLoaded) return;
        this.chartJsLoaded = true;

        loadScript(this, ChartJS)
            .then(() => {
                this.renderChart();
            })
            .catch(error => {
                console.error('ChartJS load error', error);
            });
    }

    renderChart() {
        if (!this.chartJsLoaded || !this.dataLoaded) return;

        const canvas = this.template.querySelector('[data-id="orderChart"]');
        if (!canvas) return;

        if (this.chart) {
            this.chart.destroy();
        }

        const ctx = canvas.getContext('2d');

        this.chart = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: this.wiredResult.data.map(item => item.label),
               datasets: [{
    data: this.wiredResult.data.map(item => item.value),

    backgroundColor: this.wiredResult.data.map(item => {

        if (item.label === 'Approved') {
            return '#2dd4bf';
        }

        if (item.label === 'Pending') {
            return '#f59e0b';
        }

        if (item.label === 'Rejected') {
            return '#ef4444';
        }

        if (item.label === 'Cancelled') {
            return '#a855f7';
        }

        return '#94a3b8';
    }),

    borderWidth: 3,
    borderColor: '#ffffff'
}]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            usePointStyle: true,
                            pointStyle: 'circle',
                            padding: 20,
                            font: {
                                size: 13
                            }
                        }
                    }
                }
            }
        });
    }
}
