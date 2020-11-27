//--- display the window of input parameters when launching the script

//--- filter
string InpFilter="*.x.txt";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
  // string param=checkParam();
   AccInfo Acc;
   datetime from,till;
   bool isok=initFile();
   
   string str=(int)GlobalVariableGet("xfrom");
   //str="20201116";
   string ss=StringConcatenate(StringSubstr(str,0,4),".",StringSubstr(str,4,2),".",StringSubstr(str,6,2));

   from=StringToTime(ss);
   str=(int)GlobalVariableGet("xtill");
  // str="20201120";
   ss=StringConcatenate(StringSubstr(str,0,4),".",StringSubstr(str,4,2),".",StringSubstr(str,6,2));
   till=StringToTime(ss);
   
   isok=getHistory(from,till,Acc);
   isok=outputcsv(Acc);
   
   //Print("error");
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string file_name;
string checkParam()
  {

   int i;

   long search_handle=FileFindFirst(InpFilter,file_name);
//--- check if the FileFindFirst() is executed successfully
   if(search_handle!=INVALID_HANDLE)
     {
      FileFindClose(search_handle);
      string rst[],param[];
      StringSplit(file_name,'.',rst);
      StringSplit(rst[0],'-',param);
      double begin=StringToInteger(param[0]);
      double end=StringToInteger(param[1]);
      GlobalVariableSet("xfrom",StringToInteger(param[0]));
      GlobalVariableSet("xtill",StringToInteger(param[1]));
      return rst[0];
     }
   else
      return NULL;
  }

struct AccInfo
  {
   string            Name;
   string            Number;
   string            Currency;
   datetime          From;
   datetime          Till;
   string            Profit;
  };
string reportfilename="AccountRobot";  // the FileOpen has the FILE_COMMON flag meaning it is saved to the Commong/Files folder.
uchar DELIM='\t';  // Delimiter is '\t' tab.  Other options are ';' semicolon and ',' comma.  The '\t' delimiter is the default for Excel CSV imports.
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool initFile()
  {
   reportfilename=checkParam();
   
   if(reportfilename!=NULL)
     {
      reportfilename=StringConcatenate("AccountRobot_",reportfilename,".xls");
      double filehandle=FileOpen(reportfilename,FILE_READ|FILE_WRITE|FILE_CSV,DELIM); // overwrite previous file if present.  Send to local files directory.  SendFTP should work.
      if(filehandle==INVALID_HANDLE || filehandle<=0)
         return(false); // we can't open the file so exit the try.

      FileWrite(filehandle,
                "Account Name",
                "Account Number",
                "From",
                "Till",
                "Profit",
                "Currency"
               );
      FileClose(filehandle);
      
      FileDelete(file_name);
     } else {
         reportfilename=StringConcatenate("AccountRobot_",(int)GlobalVariableGet("xfrom"),"-",(int)GlobalVariableGet("xtill"),".xls");
     }
     return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool outputcsv(AccInfo &Acc)
  {
   //string reportcsv=StringConcatenate(reportfilename,"_",Acc.From,"-",Acc.Till,".csv");
   double filehandle=FileOpen(reportfilename,FILE_READ|FILE_WRITE|FILE_CSV,DELIM); // overwrite previous file if present.  Send to local files directory.  SendFTP should work.
   if(filehandle==INVALID_HANDLE || filehandle<=0)
      return(false); // we can't open the file so exit the try.
   FileSeek(filehandle,0,SEEK_END);
   FileWrite(filehandle,
             Acc.Name,
             Acc.Number,
             TimeToStr(Acc.From,TIME_DATE),
             TimeToStr(Acc.Till,TIME_DATE),
             Acc.Profit,
             Acc.Currency
            );
   FileFlush(filehandle);
   FileClose(filehandle);

  };
//+------------------------------------------------------------------+
bool getHistory(datetime from,datetime till,AccInfo &Acc)
  {
   Acc.Name=CleanString(AccountName());
   Acc.Number=AccountNumber();
   Acc.Currency=AccountCurrency();
   Acc.From=from;
   Acc.Till=till;
   double Profit=0;
  // int c=0;
   // n=OrdersHistoryTotal();
   //if(!HistorySelect(from,till)){Print("HistorySelect failed");return;}
   int i,hstTotal=OrdersHistoryTotal();
   string idlist="";
   for(i=0; i<hstTotal; i++)
     {
      //---- check selection result
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
        {
         return false;
        }
      datetime ctm=OrderCloseTime();
      int ordertype=OrderType();
      
      if(ctm>=from&&ctm<=till&&ordertype!=6)
        {
         double pp=OrderProfit()+OrderCommission()+OrderSwap();
         Profit= Profit+pp;
         //WritetoFile(OrderTicket(),pp,ordertype);
        // idlist=StringConcatenate(idlist,",", OrderTicket(),":",DoubleToStr(pp));
        // c=c+1;
        }
      // some work with order
     }
   Acc.Profit=DoubleToString(Profit,2);
   return true;

  }
void WritetoFile(string id,double value,int type)
{
      int filehandle=FileOpen("all.txt",FILE_READ|FILE_WRITE|FILE_CSV,","); // overwrite previous file if present.  Send to local files directory.  SendFTP should work.
      if(filehandle==INVALID_HANDLE || filehandle<=0) return(false); // we can't open the file so exit the try.
      FileSeek(filehandle,0,SEEK_END);
      FileWrite(filehandle,id,DoubleToStr(value),type);
      FileClose(filehandle);
 
}
//+------------------------------------------------------------------+
//| Make string safe for .CSV files using comma, tab or semi-colon as seperator
//+------------------------------------------------------------------+
string CleanString(string s)
  {
   string temp=s;
   StringReplace(temp,";","|"); // replace any ';' with '|' to avoid the field delimiter in the .csv file
   StringReplace(temp,",","|"); // replace any ',' with '|' to avoid the field delimiter in the .csv file
   StringReplace(temp,"\t"," "); // replace any {tab} with {space} to avoid the field delimiter in the .csv file
   return(temp);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CleanDateTime(datetime d)
  {
   return(StringConcatenate(CleanDate(d)," ",CleanTime(d)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CleanDate(datetime d)
  {
   string temp;

   temp=StringConcatenate("00",IntegerToString(TimeYear(d)));
   string yyyy=StringSubstr(temp,(StringLen(temp)-4),4);

   temp=StringConcatenate("00",IntegerToString(TimeMonth(d)));
   string mm=StringSubstr(temp,(StringLen(temp)-2),2);

   temp=StringConcatenate("00",IntegerToString(TimeDay(d)));
   string dd=StringSubstr(temp,(StringLen(temp)-2),2);

   return(StringConcatenate(dd,"-",mm,"-",yyyy));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CleanTime(datetime d)
  {
   string temp;

   temp=StringConcatenate("00",IntegerToString(TimeHour(d)));
   string hh=StringSubstr(temp,(StringLen(temp)-2),2);

   temp=StringConcatenate("00",IntegerToString(TimeMinute(d)));
   string mi=StringSubstr(temp,(StringLen(temp)-2),2);

   temp=StringConcatenate("00",IntegerToString(TimeSeconds(d)));
   string ss=StringSubstr(temp,(StringLen(temp)-2),2);

   return(StringConcatenate(hh,":",mi,":",ss));
  }
//+------------------------------------------------------------------+
