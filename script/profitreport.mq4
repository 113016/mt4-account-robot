//-----------------------------------------------------------------------------------
//                                                                   ProfitReport.mq5
//                                          Copyright 2011, MetaQuotes Software Corp.
//                                                                http://www.mql5.com
//-----------------------------------------------------------------------------------
#property copyright   "Copyright 2011, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property version     "1.00"
#property script_show_inputs

#include <Arrays\ArrayLong.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayString.mqh>
#include <Arrays\ArrayInt.mqh>

//--- input parameters
input int nD=30;               // Number of days
//--- global
double   balabce_cur=0;        // balance
double   initbalance_cur=0;    // Initial balance (not including deposits to the account)
int      days_num;             // number of days in the report (including the current day)
datetime tfrom_tim;            // Date from
datetime tend_tim;             // Date to
double   netprofit_cur=0;      // Total Net Profit
double   grossprofit_cur=0;    // Gross Profit
double   grossloss_cur=0;      // Gross Loss
int      totaltrades_num=0;    // Total Trades
int      longtrades_num=0;     // Number of Long Trades
double   longtrades_perc=0;    // % of Long Trades
int      shorttrades_num=0;    // Number of Short Trades
double   shorttrades_perc=0;   // % of Short Trades
int      proftrad_num=0;       // Number of All Profit Trades
double   proftrad_perc=0;      // % of All Profit Trades
int      losstrad_num=0;       // Number of All Loss Trades
double   losstrad_perc=0;      // % of All Loss Trades
int      shortprof_num=0;      // Number of Short Profit Trades
double   shortprof_perc=0;     // % of Short Profit Trades
double   shortloss_perc=0;     // % of Short Loss Trades
int      longprof_num=0;       // Number of Long Profit Trades
double   longprof_perc=0;      // % of Long Profit Trades
double   longloss_perc=0;      // % of Long Loss Trades
int      maxconswins_num=0;    // Number of Maximum consecutive wins
double   maxconswins_cur=0;    // Maximum consecutive wins ($)
int      maxconsloss_num=0;    // Number of Maximum consecutive losses
double   maxconsloss_cur=0;    // Maximum consecutive losses ($)
int      aveconswins_num=0;    // Number of Average consecutive wins
double   aveconswins_cur=0;    // Average consecutive wins ($)
int      aveconsloss_num=0;    // Number of Average consecutive losses
double   aveconsloss_cur=0;    // Average consecutive losses ($)
double   largproftrad_cur=0;   // Largest profit trade
double   averproftrad_cur=0;   // Average profit trade
double   larglosstrad_cur=0;   // Largest loss trade
double   averlosstrad_cur=0;   // Average loss trade
double   profitfactor=0;       // Profit Factor
double   expectpayoff=0;       // Expected Payoff
double   recovfactor=0;        // Recovery Factor
double   sharperatio=0;        // Sharpe Ratio
double   ddownabs_cur=0;       // Balance Drawdown Absolute
double   ddownmax_cur=0;       // Balance Drawdown Maximal
double   ddownmax_perc=0;      // % of Balance Drawdown Maximal
int      symbols_num=0;        // Numbre of Symbols

string       Band="";
double       Probab[33],Normal[33];
CArrayLong   TimTrad;
CArrayDouble ValTrad;
CArrayString SymNam;
CArrayInt    nSymb;
//-----------------------------------------------------------------------------------
// Script program start function
//-----------------------------------------------------------------------------------
void OnStart()
  {
   int         i,n,m,k,nwins=0,nloss=0,naverw=0,naverl=0,nw=0,nl=0;
   double      bal,sum,val,p,stdev,vwins=0,vloss=0,averwin=0,averlos=0,pmax=0;
   MqlDateTime dt;
   datetime    ttmp,it;
   string      symb,br;
   ulong       ticket;
   long        dtype,entry;

   if(!TerminalInfoInteger(TERMINAL_CONNECTED)){printf("Terminal not connected.");return;}
   days_num=nD;
   if(days_num<1)days_num=1;             // number of days in the report (including the current day)
   tend_tim=TimeCurrent();                                                // date to
   tfrom_tim=tend_tim-(days_num-1)*86400;
   TimeToStruct(tfrom_tim,dt);
   dt.sec=0; dt.min=0; dt.hour=0;
   tfrom_tim=StructToTime(dt);                                            // date from
//---------------------------------------- Bands
   ttmp=tfrom_tim;
   br="";
   if(dt.day_of_week==6 || dt.day_of_week==0)
     {
      Band+=(string)(ulong)(ttmp*1000)+",";
      br=",";ttmp+=86400;
     }
   for(it=ttmp;it<tend_tim;it+=86400)
     {
      TimeToStruct(it,dt);
      if(dt.day_of_week==6){Band+=br+(string)(ulong)(it*1000)+","; br=",";}
      if(dt.day_of_week==1&&br==",") Band+=(string)(ulong)(it*1000);
     }
   if(dt.day_of_week==6 || dt.day_of_week==0) Band+=(string)(ulong)(tend_tim*1000);

//----------------------------------------
   balabce_cur=AccountInfoDouble(ACCOUNT_BALANCE);                          // Balance

   //if(!HistorySelect(tfrom_tim,tend_tim)){Print("HistorySelect failed");return;}
   
   n=OrdersHistoryTotal();                                         // Number of Deals
   for(i=0;i<n;i++)
     {
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
        {
         return false;
        }
        datetime ctm=OrderOpenTime();
        int ordertype=OrderType();
        if(ctm>=tfrom_tim&&ctm<=tend_tim&&ordertype!=6)
        {
           //Profit= Profit+OrderProfit()+OrderCommission()+OrderSwap();
    
            totaltrades_num++;                                          // Total Trades
            val=OrderProfit();
            val+=OrderCommission();
            val+=OrderSwap();
            netprofit_cur+=val;                                         // Total Net Profit
            if(-netprofit_cur>ddownabs_cur)ddownabs_cur=-netprofit_cur; // Balance Drawdown Absolute
            if(netprofit_cur>pmax)pmax=netprofit_cur;
            p=pmax-netprofit_cur;
            if(p>ddownmax_cur)
              {
               ddownmax_cur=p;                                 // Balance Drawdown Maximal
               ddownmax_perc=pmax;
              }
            if(val>=0) //win
              {
               grossprofit_cur+=val;                            // Gross Profit 
               proftrad_num++;                                  // Number of Profit Trades
               if(val>largproftrad_cur)largproftrad_cur=val;    // Largest profit trade
               nwins++;vwins+=val;
               if(nwins>=maxconswins_num)
                 {
                  maxconswins_num=nwins;
                  if(vwins>maxconswins_cur)maxconswins_cur=vwins;
                 }
               if(vloss>0){averlos+=vloss; nl+=nloss; naverl++;}
               nloss=0;vloss=0;
              }
            else                    //loss
              {
               grossloss_cur-=val;                                   // Gross Loss
               if(-val>larglosstrad_cur)larglosstrad_cur=-val;       // Largest loss trade
               nloss++;vloss-=val;
               if(nloss>=maxconsloss_num)
                 {
                  maxconsloss_num=nloss;
                  if(vloss>maxconsloss_cur)maxconsloss_cur=vloss;
                 }
               if(vwins>0){averwin+=vwins; nw+=nwins; naverw++;}
               nwins=0;vwins=0;
              }
            if(dtype==OP_SELL)
              {
               longtrades_num++;                          // Number of Long Trades
               if(val>=0)longprof_num++;                  // Number of Long Profit Trades
              }
            else if(val>=0)shortprof_num++;               // Number of Short Profit Trades

            symb=OrderSymbol();   // Symbols
            k=1;
            for(m=0;m<SymNam.Total();m++)
              {
               if(SymNam.At(m)==symb)
                 {
                  k=0;
                  nSymb.Update(m,nSymb.At(m)+1);
                 }
              }
            if(k==1)
              {
               SymNam.Add(symb);
               nSymb.Add(1);
              }

            ValTrad.Add(val);
            TimTrad.Add(OrderOpenTime());
           }
        
     }
   if(vloss>0){averlos+=vloss; nl+=nloss; naverl++;}
   if(vwins>0){averwin+=vwins; nw+=nwins; naverw++;}
   initbalance_cur=balabce_cur-netprofit_cur;
   if(totaltrades_num>0)
     {
      longtrades_perc=NormalizeDouble((double)longtrades_num/totaltrades_num*100,1);  // % of Long Trades
      shorttrades_num=totaltrades_num-longtrades_num;                                 // Number of Short Trades
      shorttrades_perc=100-longtrades_perc;                                           // % of Short Trades
      proftrad_perc=NormalizeDouble((double)proftrad_num/totaltrades_num*100,1);      // % of Profit Trades
      losstrad_num=totaltrades_num-proftrad_num;                                      // Number of Loss Trades
      losstrad_perc=100-proftrad_perc;                                                // % of All Loss Trades
      if(shorttrades_num>0)
        {
         shortprof_perc=NormalizeDouble((double)shortprof_num/shorttrades_num*100,1);  // % of Short Profit Trades
         shortloss_perc=100-shortprof_perc;                                            // % of Short Loss Trades
        }
      if(longtrades_num>0)
        {
         longprof_perc=NormalizeDouble((double)longprof_num/longtrades_num*100,1);     // % of Long Profit Trades
         longloss_perc=100-longprof_perc;                                              // % of Long Loss Trades
        }
      if(grossloss_cur>0)profitfactor=NormalizeDouble(grossprofit_cur/grossloss_cur,2);  // Profit Factor
      if(proftrad_num>0)averproftrad_cur=NormalizeDouble(grossprofit_cur/proftrad_num,2);// Average profit trade
      if(losstrad_num>0)averlosstrad_cur=NormalizeDouble(grossloss_cur/losstrad_num,2);  // Average loss trade
      if(naverw>0)
        {
         aveconswins_num=(int)NormalizeDouble((double)nw/naverw,0);
         aveconswins_cur=NormalizeDouble(averwin/naverw,2);
        }
      if(naverl>0)
        {
         aveconsloss_num=(int)NormalizeDouble((double)nl/naverl,0);
         aveconsloss_cur=NormalizeDouble(averlos/naverl,2);
        }
      p=initbalance_cur+ddownmax_perc;
      if(p!=0)
        {
         ddownmax_perc=NormalizeDouble(ddownmax_cur/p*100,1); // % of Balance Drawdown Maximal
        }
      if(ddownmax_cur>0)recovfactor=NormalizeDouble(netprofit_cur/ddownmax_cur,2); // Recovery Factor

      expectpayoff=netprofit_cur/totaltrades_num;                    // Expected Payoff

      sum=0;
      val=balabce_cur;
      for(m=ValTrad.Total()-1;m>=0;m--)
        {
         bal=val-ValTrad.At(m);
         p=val/bal;
         sum+=p;
         val=bal;
        }
      sum=sum/ValTrad.Total();
      stdev=0;
      val=balabce_cur;
      for(m=ValTrad.Total()-1;m>=0;m--)
        {
         bal=val-ValTrad.At(m);
         p=val/bal-sum;
         stdev+=p*p;
         val=bal;
        }
      stdev=MathSqrt(stdev/ValTrad.Total());
      if(stdev>0)sharperatio=NormalizeDouble((sum-1)/stdev,2);    // Sharpe Ratio

      stdev=0;
      for(m=0;m<ValTrad.Total();m++)
        {
         p=ValTrad.At(m)-expectpayoff;
         stdev+=p*p;
        }
      stdev=MathSqrt(stdev/ValTrad.Total());                      // Standard deviation
      if(stdev>0)
        {
         ArrayInitialize(Probab,0.0);
         for(m=0;m<ValTrad.Total();m++) // Histogram
           {
            i=16+(int)NormalizeDouble((ValTrad.At(m)-expectpayoff)/stdev,0);
            if(i>=0 && i<ArraySize(Probab))Probab[i]++;
           }
         for(m=0;m<ArraySize(Probab);m++) Probab[m]=NormalizeDouble(Probab[m]/totaltrades_num,5);
        }
      expectpayoff=NormalizeDouble(expectpayoff,2);  // Expected Payoff  
      k=0;
      symbols_num=SymNam.Total();                    // Symbols
      for(m=0;m<(6-symbols_num);m++)
        {
         if(k==0)
           {
            k=1;
            SymNam.Insert("",0);
            nSymb.Insert(0,0);
           }
         else
           {
            k=1;
            SymNam.Add("");
            nSymb.Add(0);
           }
        }
     }
   p=1.0/MathSqrt(2*M_PI)/4.0;
   for(m=0;m<ArraySize(Normal);m++) // Normal distribution
     {
      val=(double)m/4.0-4;
      Normal[m]=NormalizeDouble(p*MathExp(-val*val/2),5);
     }

   filesave();
  }
//-----------------------------------------------------------------------------------
// Save file
//-----------------------------------------------------------------------------------
void filesave()
  {
   int n,fhandle;
   string loginame,str="",br="";
   double sum;

   ResetLastError();
   fhandle=FileOpen("data.txt",FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(fhandle<0){Print("File open failed, error ",GetLastError());return;}

   loginame="\""+(string)AccountInfoInteger(ACCOUNT_LOGIN)+", "+
            TerminalInfoString(TERMINAL_COMPANY)+"\"";
   str+="var PName="+loginame+";\n";
   str+="var Currency=\""+AccountInfoString(ACCOUNT_CURRENCY)+"\";\n";
   str+="var Balance="+(string)balabce_cur+";\n";
   str+="var IniBalance="+(string)initbalance_cur+";\n";
   str+="var nDays="+(string)days_num+";\n";
   str+="var T1="+(string)(ulong)(tfrom_tim*1000)+";\n";
   str+="var T2="+(string)(ulong)(tend_tim*1000)+";\n";
   str+="var NetProf="+DoubleToString(netprofit_cur,2)+";\n";
   str+="var GrossProf="+DoubleToString(grossprofit_cur,2)+";\n";
   str+="var GrossLoss="+DoubleToString(grossloss_cur,2)+";\n";
   str+="var TotalTrad="+(string)totaltrades_num+";\n";
   str+="var NProfTrad="+(string)proftrad_num+";\n";
   str+="var ProfTrad="+DoubleToString(proftrad_perc,1)+";\n";
   str+="var NLossTrad="+(string)losstrad_num+";\n";
   str+="var LossTrad="+DoubleToString(losstrad_perc,1)+";\n";
   str+="var NLongTrad="+(string)longtrades_num+";\n";
   str+="var LongTrad="+DoubleToString(longtrades_perc,1)+";\n";
   str+="var NShortTrad="+(string)shorttrades_num+";\n";
   str+="var ShortTrad="+DoubleToString(shorttrades_perc,1)+";\n";
   str+="var ProfLong ="+DoubleToString(longprof_perc,1)+";\n";
   str+="var LossLong ="+DoubleToString(longloss_perc,1)+";\n";
   FileWriteString(fhandle,str); str="";
   str+="var ProfShort="+DoubleToString(shortprof_perc,1)+";\n";
   str+="var LossShort="+DoubleToString(shortloss_perc,1)+";\n";
   str+="var ProfFact="+DoubleToString(profitfactor,2)+";\n";
   str+="var LargProfTrad="+DoubleToString(largproftrad_cur,2)+";\n";
   str+="var AverProfTrad="+DoubleToString(averproftrad_cur,2)+";\n";
   str+="var LargLosTrad="+DoubleToString(larglosstrad_cur,2)+";\n";
   str+="var AverLosTrad="+DoubleToString(averlosstrad_cur,2)+";\n";
   str+="var NMaxConsWin="+(string)maxconswins_num+";\n";
   str+="var MaxConsWin="+DoubleToString(maxconswins_cur,2)+";\n";
   str+="var NMaxConsLos="+(string)maxconsloss_num+";\n";
   str+="var MaxConsLos="+DoubleToString(maxconsloss_cur,2)+";\n";
   str+="var NAveConsWin="+(string)aveconswins_num+";\n";
   str+="var AveConsWin="+DoubleToString(aveconswins_cur,2)+";\n";
   str+="var NAveConsLos="+(string)aveconsloss_num+";\n";
   str+="var AveConsLos="+DoubleToString(aveconsloss_cur,2)+";\n";
   str+="var ExpPayoff="+DoubleToString(expectpayoff,2)+";\n";
   str+="var AbsDD="+DoubleToString(ddownabs_cur,2)+";\n";
   str+="var MaxDD="+DoubleToString(ddownmax_cur,2)+";\n";
   str+="var RelDD="+DoubleToString(ddownmax_perc,1)+";\n";
   str+="var RecFact="+DoubleToString(recovfactor,2)+";\n";
   str+="var Sharpe="+DoubleToString(sharperatio,2)+";\n";
   str+="var nSymbols="+(string)symbols_num+";\n";
   FileWriteString(fhandle,str);

   str="";br="";
   for(n=0;n<ArraySize(Normal);n++)
     {
      str+=br+"["+DoubleToString(((double)n-16)/4.0,2)+","+DoubleToString(Normal[n],5)+"]";
      br=",";
     }
   FileWriteString(fhandle,"var Normal=["+str+"];\n");

   str="";
   str="[-4.25,0]";
   for(n=0;n<ArraySize(Probab);n++)
     {
      if(Probab[n]>0)
        {
         str+=",["+DoubleToString(((double)n-16)/4.0,2)+","+DoubleToString(Probab[n],5)+"]";
        }
     }
   str+=",[4.25,0]";
   FileWriteString(fhandle,"var Probab=["+str+"];\n");

   str=""; sum=0;
   if(ValTrad.Total()>0)
     {
      sum+=ValTrad.At(0);
      str+="["+(string)(ulong)(TimTrad.At(0)*1000)+","+DoubleToString(sum,2)+"]";
      for(n=1;n<ValTrad.Total();n++)
        {
         sum+=ValTrad.At(n);
         str+=",["+(string)(ulong)(TimTrad.At(n)*1000)+","+DoubleToString(sum,2)+"]";
        }
     }
   FileWriteString(fhandle,"var Prof=["+str+"];\n");
   FileWriteString(fhandle,"var Band=["+Band+"];\n");

   str="";br="";
   for(n=0;n<SymNam.Total();n++)
     {
      str+=br+"{name:\'"+SymNam.At(n)+"\',data:["+(string)nSymb.At(n)+"]}";
      br=",";
     }
   FileWriteString(fhandle,"var Sym=["+str+"];\n");

   FileClose(fhandle);
  }
//+------------------------------------------------------------------+
