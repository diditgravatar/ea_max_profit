//+------------------------------------------------------------------+
//| Expert Advisor: XAUUSD Auto Trading EA                          |
//| Deskripsi: EA untuk trading XAUUSD dengan ADX, RSI, MA          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>  // Library trading
CTrade trade;               // Objek trading

// === INPUT PARAMETER ===
input double LotSize = 0.1;           // Ukuran lot default
input double RiskPerTrade = 2;        // Risiko per trade dalam persen
input int ADX_Period = 14;            // Periode ADX
input double ADX_Threshold = 25;      // Batas ADX untuk tren kuat
input int RSI_Period = 14;            // Periode RSI
input int RSI_Buy_Level = 70;         // Level overbought untuk sell
input int RSI_Sell_Level = 30;        // Level oversold untuk buy
input int MA_Short = 35;              // MA cepat (35)
input int MA_Long = 82;               // MA lambat (82)
input int ATR_Period = 14;            // Periode ATR untuk Stop Loss
input bool UseTrailingStop = true;    // Gunakan trailing stop?
input bool UseBreakEven = true;       // Gunakan break-even stop?
input bool UseHedging = false;        // Aktifkan mode hedging?
input double MaxDrawdown = 10;        // Maksimal drawdown (%) sebelum EA berhenti

// Variabel Global
double adx, rsi, maShort, maLong, atr;
double AccountStartBalance;

//+------------------------------------------------------------------+
//| Fungsi untuk mendapatkan nilai indikator                        |
//+------------------------------------------------------------------+
void GetIndicators() {
   adx = iADX(Symbol(), PERIOD_M15, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
   rsi = iRSI(Symbol(), PERIOD_M15, RSI_Period, PRICE_CLOSE, 0);
   maShort = iMA(Symbol(), PERIOD_M15, MA_Short, 0, MODE_SMA, PRICE_CLOSE, 0);
   maLong = iMA(Symbol(), PERIOD_M15, MA_Long, 0, MODE_SMA, PRICE_CLOSE, 0);
   atr = iATR(Symbol(), PERIOD_M15, ATR_Period, 0);
}

//+------------------------------------------------------------------+
//| Fungsi untuk mengecek sinyal BUY                                 |
//+------------------------------------------------------------------+
bool CheckBuySignal() {
   return (adx > ADX_Threshold && rsi < RSI_Buy_Level && maShort > maLong && (maShort - maLong) * Point >= 200 * Point);
}

//+------------------------------------------------------------------+
//| Fungsi untuk mengecek sinyal SELL                                |
//+------------------------------------------------------------------+
bool CheckSellSignal() {
   return (adx > ADX_Threshold && rsi > RSI_Sell_Level && maShort < maLong && (maLong - maShort) * Point >= 200 * Point);
}

//+------------------------------------------------------------------+
//| Fungsi untuk menghitung Stop Loss & Take Profit                 |
//+------------------------------------------------------------------+
double CalculateStopLoss() { return atr * 2; }   // SL = 2x ATR
double CalculateTakeProfit() { return atr * 4; } // TP = 4x ATR

//+------------------------------------------------------------------+
//| Fungsi untuk membuka posisi trade                               |
//+------------------------------------------------------------------+
void OpenTrade() {
   GetIndicators(); // Ambil data indikator
   double sl = CalculateStopLoss();
   double tp = CalculateTakeProfit();

   if (CheckBuySignal()) {
      trade.Buy(LotSize, Symbol(), 0, sl, tp, "BUY XAUUSD");
   }
   if (CheckSellSignal()) {
      trade.Sell(LotSize, Symbol(), 0, sl, tp, "SELL XAUUSD");
   }
}

//+------------------------------------------------------------------+
//| Fungsi untuk mengaktifkan Trailing Stop                         |
//+------------------------------------------------------------------+
void ApplyTrailingStop() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      double currentPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double stopLoss = PositionGetDouble(POSITION_SL);
      double newStopLoss = 0;

      if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         newStopLoss = currentPrice - (atr * 1.5);
         if (newStopLoss > stopLoss) trade.PositionModify(ticket, newStopLoss, 0);
      } else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         newStopLoss = currentPrice + (atr * 1.5);
         if (newStopLoss < stopLoss) trade.PositionModify(ticket, newStopLoss, 0);
      }
   }
}

//+------------------------------------------------------------------+
//| Fungsi untuk mengecek drawdown                                  |
//+------------------------------------------------------------------+
bool CheckMaxDrawdown() {
   double equity = AccountEquity();
   double drawdown = 100 * (AccountStartBalance - equity) / AccountStartBalance;
   return (drawdown >= MaxDrawdown);
}

//+------------------------------------------------------------------+
//| Fungsi utama EA                                                 |
//+------------------------------------------------------------------+
void OnTick() {
   GetIndicators(); // Ambil data indikator

   // Cek drawdown sebelum eksekusi trading
   if (CheckMaxDrawdown()) {
      Print("Max drawdown tercapai! EA berhenti trading.");
      return;
   }

   // Cek apakah ada posisi yang sudah terbuka
   int totalOrders = PositionsTotal();
   
   // Jika tidak ada posisi terbuka, cari sinyal baru
   if (totalOrders == 0) {
      OpenTrade();
   }
   
   // Jika Trailing Stop diaktifkan, jalankan fungsinya
   if (UseTrailingStop) {
      ApplyTrailingStop();
   }
}

//+------------------------------------------------------------------+
//| Fungsi untuk inisialisasi EA                                    |
//+------------------------------------------------------------------+
int OnInit() {
   AccountStartBalance = AccountBalance();
   Print("EA XAUUSD dimulai! Balance awal: ", AccountStartBalance);
   return INIT_SUCCEEDED;
}
