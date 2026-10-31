### IMPORT LIBRARY ###
library(quantmod)
library(dplyr)
library(lubridate)
library(openxlsx)
library(neuralnet)
library(ggplot2)
library(psych)

### IMPORT DATA ###
## Ambil data BBRI ##
getSymbols("BBRI.JK", src = "yahoo", from = "2020-01-01", to = "2024-12-31")
data <- data.frame(Date = index(BBRI.JK), coredata(BBRI.JK))
data <- data[, -5]
View(data)

## Data Selection ##
# Ambil tanggal perdagangan terakhir setiap bulan
data_bulanan <- data %>%
  group_by(bulan = floor_date(Date, "month")) %>%  # grup berdasarkan bulan
  slice_tail(n = 1) %>%                            # ambil baris terakhir per bulan
  ungroup() %>%
  dplyr::select(-bulan) 
colnames(data_bulanan) <- c("Tanggal", "Buka", "Tinggi", "Rendah", "Volume", "Target")
View(data_bulanan)

### ANALISIS DESKRIPTIF ###
# Statistik deskriptif tiap kolom
describe(data_bulanan[,(-1)])

### PREPROCESSING DATA ###
## Data Cleaning ##
# Pengecekkan Data Missing
is.na(data_bulanan)
sum(is.na(data_bulanan))

# Pengecekkan Data Duplikat
any(duplicated(data_bulanan))

## Data Transformation ##
# normalisasi data
maxs <-apply(data_bulanan[,-1], 2, max)
mins <-apply(data_bulanan[,-1], 2, min)
normalize<-function(x){return((x-min(x))/((max(x)-min(x))))}

scaled <-as.data.frame(scale(data_bulanan[,-1], center = mins, scale = maxs - mins))
View(scaled)

### Data Splitting ###
# pemisahan acak split data train dan data testing 80:20 #
set.seed(500)
index <-sample(1:nrow(scaled),round(0.8*nrow(scaled)))

# Pemisahan data asli #
train <-data_bulanan[index,]
test <-data_bulanan[-index,]

# pemisahan data normalisasi #
train_<-scaled[index,]
test_<-scaled[-index,]
print(paste("Data Latih:", nrow(train_)))
print(paste("Data Uji:", nrow(test_)))
View(train_)
View(test_)

### PELATIHAN NEURAL NETWORK ###
set.seed(500)
nn <-neuralnet(Target~Buka+Tinggi+Rendah+Volume, 
               data=train_, 
               hidden=c(3), 
               linear.output = T, 
               threshold = 0.01)
print(nn)

# plot dan cek weights #
plot(nn)
nn$startweights
nn$result.matrix

# uji output yang dihasilkan #
temp_test<-subset(test_, select =c("Buka","Tinggi","Rendah","Volume"))
temp_test

# menghitung prediksi #
nn.results <- compute(nn, temp_test)
results <- data.frame(actual=test_$Target, prediction=nn.results$net.result)
View(results)

### DENORMALISASI ###
max_target <- maxs["Target"]
min_target <- mins["Target"]

# mengembalikan nilai ke harga asli #
actual_values <- (results$actual * (max_target - min_target)) + min_target
predictions <- (results$prediction * (max_target - min_target)) + min_target

# Buat dataframe hasil akhir untuk evaluasi
results_final <- data.frame(
  Indeks = 1:nrow(test_),
  Actual = actual_values,
  Prediction = predictions
  )
View(results_final)

### MENGHITUNG ERROR (MSE & MAPE & MAE) ###
MSE <-sum((results_final$Actual - results_final$Prediction)^2)/nrow(results_final)
MAPE <- mean(abs((results_final$Actual - results_final$Prediction) / results_final$Actual)) * 100
cat("Mean Squared Error (MSE):", MSE, "\n")
cat("Mean Absolute Percentage Error (MAPE):", MAPE, "%\n")

pred_train_scaled <- compute(nn, train_[,1:4])$net.result
pred_train_rp <- (pred_train_scaled * (max_target - min_target)) + min_target
act_train_rp <- (train_$Target * (max_target - min_target)) + min_target
mae_train <- mean(abs(act_train_rp - pred_train_rp))
mae_test <- mean(abs(actual_values - predictions))
cat("MAE Training: ", mae_train, "\n")
cat("MAE Testing : ", mae_test, "\n")

mae_comparison <- data.frame(
  Tipe = c("Training", "Testing"),
  Nilai_MAE = c(mae_train, mae_test)
)
ggplot(mae_comparison, aes(x = Tipe, y = Nilai_MAE, fill = Tipe)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = round(Nilai_MAE, 2)), vjust = -0.5) +
  scale_fill_manual(values = c("Training" = "blue", "Testing" = "pink")) +
  labs(title = "MAE Curve Comparison (Rupiah)",
       subtitle = "Pemeriksaan Overfitting: Training vs Testing",
       y = "Mean Absolute Error (IDR)",
       x = "") +
  theme_classic()

### VISUALISASI ###
# Plot actual vs. predicted values
ggplot(results_final, aes(x = Indeks)) + 
  geom_line(aes(y = Actual, color = "Aktual"), size = 1) + 
  geom_line(aes(y = Prediction, color = "Prediksi"), linetype = "dashed", size = 1) +
  labs(title = "Perbandingan Harga Saham BBRI: Aktual vs Prediksi",
       x = "Data Uji (Bulan)",
       y = "Harga Saham") +
  scale_color_manual(name = "Keterangan", values = c("Aktual" = "blue", "Prediksi" = "red")) +
  theme_minimal()

list_laporan <- list("Data Normalisasi" = scaled,
                     "Data Training" = train_,
                     "Data Testing" = test_,
                     "Hasil Prediksi" = results_final
                     )

results_train <- data.frame(
  Indeks = 1:length(act_train_rp),
  Actual = act_train_rp,
  Prediction = pred_train_rp
)

ggplot(results_train, aes(x = Indeks)) +
  geom_line(aes(y = Actual, color = "Aktual"), size = 1) +
  geom_line(aes(y = Prediction, color = "Prediksi"), linetype = "dashed", size = 1) +
  labs(title = "Perbandingan Aktual vs Prediksi Data Training",
       x = "Data Training",
       y = "Harga Saham") +
  scale_color_manual(name = "Keterangan",
                     values = c("Aktual" = "blue", "Prediksi" = "red")) +
  theme_minimal()

mape_train <- mean(abs((act_train_rp - pred_train_rp) / act_train_rp)) * 100
cat("MAPE Training: ", mape_train, "%\n")

