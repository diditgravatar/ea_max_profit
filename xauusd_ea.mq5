//+------------------------------------------------------------------+
//| EA XAUUSD dengan Lot Berdasarkan Equity                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

// === INPUT PARAMETER ===
input double RiskPercent = 2.0;  // Risiko per trade dalam persen
input int ADX_Period = 14;
input double ADX_Threshold = 25;
input int RSI_Period = 14;
input int RSI_Buy_Level = 70;
input int RSI_Sell_Level = 30;
input int MA_Short = 35;
input int MA_Long = 82;
input int ATR_Period = 14;
input double MaxDrawdown = 10;
input int ConfirmationTimeframe = PERIOD_H1; // Konfirmasi dari H1

double AccountStartBalance;

//+------------------------------------------------------------------+
//| Fungsi untuk mendapatkan nilai indikator di Timeframe tertentu |
//+------------------------------------------------------------------+
double GetIndicatorValue(string type, ENUM_TIMEFRAMES tf) {
   if (type == "ADX") return iADX(Symbol(), tf, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
   if (type == "RSI") return iRSI(Symbol(), tf, RSI_Period, PRICE_CLOSE, 0);
   if (type == "MA_Short") return iMA(Symbol(), tf, MA_Short, 0, MODE_SMA, PRICE_CLOSE, 0);
   if (type == "MA_Long") return iMA(Symbol(), tf, MA_Long, 0, MODE_SMA, PRICE_CLOSE, 0);
   if (type == "ATR") return iATR(Symbol(), tf, ATR_Period, 0);
   return 0;
}

//+------------------------------------------------------------------+
//| Fungsi untuk menghitung Lot berdasarkan Equity                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl) {
   double equity = AccountEquity();
   double riskAmount = (equity * RiskPercent) / 100.0;
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double lotSize = riskAmount / (sl * tickValue);
   return NormalizeDouble(lotSize, 2);  // Membulatkan lot size ke 2 desimal
}

//+------------------------------------------------------------------+
//| Fungsi untuk mengecek sinyal BUY & konfirmasi H1                |
//+------------------------------------------------------------------+
bool CheckBuySignal() {
   double adxM15 = GetIndicatorValue("ADX", PERIOD_M15);
   double rsiM15 = GetIndicatorValue("RSI", PERIOD_M15);
   double maShortM15 = GetIndicatorValue("MA_Short", PERIOD_M15);
   double maLongM15 = GetIndicatorValue("MA_Long", PERIOD_M15);

   double maShortH1 = GetIndicatorValue("MA_Short", PERIOD_H1);
   double maLongH1 = GetIndicatorValue("MA_Long", PERIOD_H1);

   return (adxM15 > ADX_Threshold && rsiM15 < RSI_Sell_Level && 
           maShortM15 > maLongM15 && maShortH1 > maLongH1);
}

//+------------------------------------------------------------------+
//| Fungsi untuk mengecek sinyal SELL & konfirmasi H1               |
//+------------------------------------------------------------------+
bool CheckSellSignal() {
   double adxM15 = GetIndicatorValue("ADX", PERIOD_M15);
   double rsiM15 = GetIndicatorValue("RSI", PERIOD_M15);
   double maShortM15 = GetIndicatorValue("MA_Short", PERIOD_M15);
   double maLongM15 = GetIndicatorValue("MA_Long", PERIOD_M15);

   double maShortH1 = GetIndicatorValue("MA_Short", PERIOD_H1);
   double maLongH1 = GetIndicatorValue("MA_Long", PERIOD_H1);

   return (adxM15 > ADX_Threshold && rsiM15 > RSI_Buy_Level && 
           maShortM15 < maLongM15 && maShortH1 < maLongH1);
}

//+------------------------------------------------------------------+
//| Fungsi untuk membuka posisi trade                               |
//+------------------------------------------------------------------+
void OpenTrade() {
   double atr = GetIndicatorValue("ATR", PERIOD_M15);
   double sl = atr * 2;
   double tp = atr * 4;
   double lotSize = CalculateLotSize(sl);

   if (CheckBuySignal() && PositionsTotal() == 0) {
      trade.Buy(lotSize, Symbol(), 0, sl, tp, "BUY XAUUSD");
   }
   if (CheckSellSignal() && PositionsTotal() == 0) {
      trade.Sell(lotSize, Symbol(), 0, sl, tp, "SELL XAUUSD");
   }
}

//+------------------------------------------------------------------+
//| Fungsi untuk mengecek Max Drawdown                              |
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
   if (CheckMaxDrawdown()) {
      Print("Max drawdown tercapai! EA berhenti trading.");
      return;
   }

   if (PositionsTotal() == 0) {
      OpenTrade();
   }
}

//+------------------------------------------------------------------+
//| Fungsi untuk inisialisasi EA                                    |
//+------------------------------------------------------------------+
int OnInit() {
   AccountStartBalance = AccountBalance();
   Print("EA XAUUSD Optimal dimulai! Balance awal: ", AccountStartBalance);
   return INIT_SUCCEEDED;
}
