# artificial-neural-networks-stock-prediction-bbri

# Prediksi Harga Saham BBRI menggunakan Artificial Neural Network (Backpropagation)

## Deskripsi Proyek
Penelitian ini bertujuan untuk membangun dan mengevaluasi model *Artificial Neural Network* (ANN) dengan algoritma *Backpropagation* guna memprediksi harga penutupan saham yang telah disesuaikan (*Adjusted Close*) dari **PT Bank Rakyat Indonesia (Persero) Tbk (BBRI.JK)**. Data yang digunakan merupakan data sekunder bulanan dari periode Januari 2020 hingga Desember 2024 yang diperoleh dari Yahoo Finance.

## Variabel & Arsitektur Model
* **Variabel Input:** Open (Pembukaan), High (Tertinggi), Low (Terendah), dan Volume perdagangan.
* **Variabel Target (Output):** Adjusted Close (Harga Penutupan yang Disesuaikan).
* **Arsitektur ANN:** Multi-Layer Perceptron (MLP) dengan 1 *hidden layer* yang terdiri dari 3 neuron (Arsitektur 4-3-1).
* **Fungsi Aktivasi:** Sigmoid (pada *hidden layer*) dan Linear (pada *output layer*).

## Hasil Evaluasi Model
* **Mean Squared Error (MSE):** 24.819,1685
* **Mean Absolute Percentage Error (MAPE):** ~3% (Model dikategorikan memiliki kemampuan prediksi yang **Sangat Akurat** karena berada di bawah 10%).
* **Pengujian Overfitting:** Berdasarkan perbandingan nilai *Mean Absolute Error* (MAE) antara data *training* (122.08) dan *testing* (125.38), model terbukti tidak mengalami *overfitting* dan mampu melakukan generalisasi dengan baik.

## Bahasa & Tools Pemrograman
* **Bahasa:** R (RStudio)
* **Library Utama:** 
  * `neuralnet` (untuk pemodelan ANN)
  * `quantmod` (untuk mengambil data historis saham)
  * `ggplot2` (untuk visualisasi grafik)
  * `dplyr` & `psych` (untuk manipulasi dan analisis deskriptif data)

## Struktur Repositori
```text
├── script/                    
│   └── ann.R               
├── report/                    
│   └── ANN BBRI.pdf
└── README.md 
