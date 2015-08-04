// ****************************************************************************************************************
//  SS_Label_Section_7.0 #PROCEDURE_SECTION
PROCEDURE_SECTION
  {
  Mgmt_quant.initialize();
  Extra_Std.initialize();
  CrashPen.initialize();

  niter++;
  if(mceval_phase() ) mceval_counter ++;   // increment the counter
  if(initial_params::mc_phase==1) mcmc_counter++;

  if(mcmcFlag==1)  //  so will do mcmc this run or is in mceval
  {
    if(Do_ParmTrace==1) Do_ParmTrace=4;  // to get all iterations
    if(Do_ParmTrace==2) Do_ParmTrace=3;  // to get all iterations
    if(mcmc_counter>10 || mceval_counter>10) Do_ParmTrace=0;
  }

//  SS_Label_Info_7.1 #Set up recruitment bias_adjustment vector
  sigmaR=SR_parm(N_SRparm2-3);
  two_sigmaRsq=2.0*sigmaR*sigmaR;
  half_sigmaRsq=0.5*sigmaR*sigmaR;

  biasadj.initialize();
  if(mcmcFlag==1)  //  so will do mcmc this run or is in mceval
  {
    biasadj_full=1.0;
  }
  else if(recdev_adj(5)<0.0)
  {
    biasadj_full=1.0;
  }
  else
  {
    for (y=styr-nages; y<=YrMax; y++)
    {
      if(y<recdev_first)  // before start of recrdevs
        {biasadj_full(y)=0.;}
      else if(y<=recdev_adj(1))
        {biasadj_full(y)=0.;}
      else if (y<=recdev_adj(2))
        {biasadj_full(y)=(y-recdev_adj(1)) / (recdev_adj(2)-recdev_adj(1))*recdev_adj(5);}
      else if (y<=recdev_adj(3))
        {biasadj_full(y)=recdev_adj(5);}   // max bias adjustment
      else if (y<=recdev_adj(4))
        {biasadj_full(y)=recdev_adj(5)-(y-recdev_adj(3)) / (recdev_adj(4)-recdev_adj(3))*recdev_adj(5);}
      else
        {biasadj_full(y)=0.;}
    }
  }

  if(SR_fxn==4 || do_recdev==0)
  {
    // keep all at 0.0 if not using SR fxn
  }
  else
  {
    if(recdev_do_early>0 && recdev_options(2)>=0 )    //  do logic on basis of recdev_options(2), which is read, not recdev_PH which can be reset to a neg. value
    {
      for (i=recdev_early_start;i<=recdev_early_end;i++)
      {biasadj(i)=biasadj_full(i);}
    }
    if(do_recdev>0 && recdev_PH_rd>=0 )
    {
      for (i=recdev_start;i<=recdev_end;i++)
      {biasadj(i)=biasadj_full(i);}
    }
    if(Do_Forecast>0 && recdev_options(3)>=0 )
    {
      for (i=recdev_end+1;i<=YrMax;i++)
      {biasadj(i)=biasadj_full(i);}
    }
    if(recdev_read>0)
    {
      for (j=1;j<=recdev_read;j++)
      {
        y=recdev_input(j,1);
        if(y>=recdev_first && y<=YrMax) biasadj(y)=biasadj_full(y);
      }
    }
  }

  sd_offset_rec=sum(biasadj)*sd_offset;

//  SS_Label_Info_7.2 #Copy recdev parm vectors into full time series vector
  if(recdev_do_early>0) {recdev(recdev_early_start,recdev_early_end)=recdev_early(recdev_early_start,recdev_early_end);}
  if(do_recdev==1)
    {recdev(recdev_start,recdev_end)=recdev1(recdev_start,recdev_end);}
  else if(do_recdev==2)
    {recdev(recdev_start,recdev_end)=recdev2(recdev_start,recdev_end);}
  if(Do_Forecast>0) recdev(recdev_end+1,YrMax)=Fcast_recruitments(recdev_end+1,YrMax);  // only needed here for reporting

//  SS_Label_Info_7.3 #Reset Fmethod 2 to Fmethod 3 according to the phase
    if(F_Method==2)
    {
      if(current_phase()>=F_setup(2) || (readparfile==1 && current_phase()<=1)) //  set Hrate = Frate parameters on first call if readparfile=1, or for advanced phases
      {
        for (g=1;g<=N_Fparm;g++)
        {
          f=Fparm_loc(g,1);
          t=Fparm_loc(g,2);
          Hrate(f,t)=F_rate(g);
        }
      }
      F_Method_use=2;
      if(current_phase() < F_setup(2)) F_Method_use=3;  // use hybrid
    }
    else
    {
      F_Method_use=F_Method;
    }

  //  SS_Label_Info_7.3.5 #Set up the MGparm stderr and rho parameters for the dev vectors
  if(N_MGparm_dev>0)
    {
      for(i=1;i<=N_MGparm_dev;i++)
      {
        MGparm_dev_stddev(i)=MGparm(MGparm_dev_rpoint2(i));
        MGparm_dev_rho(i)=MGparm(MGparm_dev_rpoint2(i)+1);
      }
    }

  //  SS_Label_Info_7.3.5 #Set up the selparm stderr and rho parameters for the dev vectors
  if(N_selparm_dev>0)
    {
      for(i=1;i<=N_selparm_dev;i++)
      {
        selparm_dev_stddev(i)=selparm(selparm_dev_rpoint2(i));
        selparm_dev_rho(i)=selparm(selparm_dev_rpoint2(i)+1);
      }
    }

//  SS_Label_Info_7.4 #Do the time series calculations
  if(mceval_counter==0 || (mceval_counter>burn_intvl &&  ((double(mceval_counter)/double(thin_intvl)) - double((mceval_counter/thin_intvl))==0)  )) // check to see if burn in period is over
  {
//  add dynamic Bzero here

    y=styr;
//  SS_Label_Info_7.4.1 #Call fxn get_initial_conditions() to get the virgin and initial equilibrium population
    get_initial_conditions();
      if(do_once==1) cout<<" OK with initial conditions "<<endl;
//  SS_Label_Info_7.4.2 #Call fxn get_time_series() to do population calculations for each year and get expected values for observations
    get_time_series();  //  in procedure_section
      if(do_once==1) cout<<" OK with time series "<<endl;

//  SS_Label_Info_7.4.3 #Call fxn evaluate_the_objective_function()
    evaluate_the_objective_function();

    if(do_once==1) 
    {
      cout<<" OK with obj_func "<<obj_fun<<endl;
      do_once=0;
    }

//  SS_Label_Info_7.5 #Get averages from selected years to use in forecasts
    if(Do_Forecast>0)
    {
//      if(save_for_report>0 || last_phase() || current_phase()==max_phase || ((sd_phase() || mceval_phase()) && (initial_params::mc_phase==0)))
      {
//  SS_Label_Info_7.5.1 #Calc average selectivity to use in forecast; store in endyr+1
        temp=float(Fcast_Sel_yr2-Fcast_Sel_yr1+1.);
        for (gg=1;gg<=gender;gg++)
        for (f=1;f<=Nfleet;f++)
        {
          tempvec_l.initialize();
          for (y=Fcast_Sel_yr1;y<=Fcast_Sel_yr2;y++) {tempvec_l+=sel_l(y,f,gg);}
          sel_l(endyr+1,f,gg)=tempvec_l/temp;

          tempvec_l.initialize();
          for (y=Fcast_Sel_yr1;y<=Fcast_Sel_yr2;y++) {tempvec_l+=sel_l_r(y,f,gg);}
          sel_l_r(endyr+1,f,gg)=tempvec_l/temp;

          tempvec_l.initialize();
          for (y=Fcast_Sel_yr1;y<=Fcast_Sel_yr2;y++) {tempvec_l+=discmort2(y,f,gg);}
          discmort2(endyr+1,f,gg)=tempvec_l/temp;

          tempvec_a.initialize();
          for (y=Fcast_Sel_yr1;y<=Fcast_Sel_yr2;y++) {tempvec_a+=sel_a(y,f,gg);}
          sel_a(endyr+1,f,gg)=tempvec_a/temp;
        }

//  SS_Label_Info_7.5.2 #Set-up relative F among fleets and seasons for forecast
        if(Fcast_RelF_Basis==1)  // set allocation according to range of years
        {
          temp=0.0;
          Fcast_RelF_Use.initialize();
          for (y=Fcast_RelF_yr1;y<=Fcast_RelF_yr2;y++)
          for (f=1;f<=Nfleet;f++)
          for (s=1;s<=nseas;s++)
          {
            t=styr+(y-styr)*nseas+s-1;
            Fcast_RelF_Use(s,f)+=Hrate(f,t);
          }
          temp=sum(Fcast_RelF_Use);
          if(temp==0.0)
          {
            Fcast_RelF_Use(1,1)=1.0;
            Fcurr_Fmult=0.0;
          }
          else
          {
            Fcast_RelF_Use/=temp;
            Fcurr_Fmult=temp/float(Fcast_RelF_yr2-Fcast_RelF_yr1+1);
          }
        }
        else  // Fcast_RelF_Basis==2 so set to values that were read
        {
          temp=0.0;
          for (f=1;f<=Nfleet;f++)
          for (s=1;s<=nseas;s++)
          {
            temp+=Fcast_RelF_Input(s,f);
          }
          Fcast_RelF_Use=Fcast_RelF_Input/temp;
          Fcurr_Fmult=temp;
        }
      }  //  end being in a phase for these calcs
    }  //  end getting quantities for forecasts

//  SS_Label_Info_7.5.3 #Calc average selectivity to use in benchmarks; store in styr-3
//  Bmark_Yr(1,6)<<" Benchmark years:  beg-end bio; beg-end selex; beg-end alloc"<<endl;

    if(Do_Benchmark>0)
    {
//      if(save_for_report>0 || last_phase() || current_phase()==max_phase || ((sd_phase() || mceval_phase()) && (initial_params::mc_phase==0)))
      {
    //  calc average body size to use in equil; store in styr-3
        temp=float(Bmark_Yr(2)-Bmark_Yr(1)+1.);  //  get denominator
        for (g=1;g<=gmorph;g++)
        if(use_morph(g)>0)
        {
          for (s=0;s<=nseas-1;s++)
          {
            tempvec_a.initialize();
            for (t=Bmark_t(1);t<=Bmark_t(2);t+=nseas) {tempvec_a+=Ave_Size(t+s,1,g);}
            Ave_Size(styr-3*nseas+s,1,g)=tempvec_a/temp;
            tempvec_a.initialize();
            for (t=Bmark_t(1);t<=Bmark_t(2);t+=nseas) {tempvec_a+=Ave_Size(t+s,mid_subseas,g);}
            Ave_Size(styr-3*nseas+s,mid_subseas,g)=tempvec_a/temp;
            for (f=0;f<=Nfleet;f++)
            {
              tempvec_a.initialize();
              for (t=Bmark_t(1);t<=Bmark_t(2);t+=nseas) {tempvec_a+=save_sel_fec(t+s,g,f);}
              save_sel_fec(styr-3*nseas+s,g,f)=tempvec_a/temp;
            }
          }
        }

        if(do_migration>0)
        {
          for (j=1;j<=do_migr2;j++)
          {
            tempvec_a.initialize();
            for (y=Bmark_Yr(1);y<=Bmark_Yr(2);y++){tempvec_a+=migrrate(y,j);}
            migrrate(styr-3,j)=tempvec_a/temp;
          }
        }

    //  calc average selectivity to use in equil; store in styr-1
        temp=float(Bmark_Yr(4)-Bmark_Yr(3)+1.);  //  get denominator
        for (gg=1;gg<=gender;gg++)
        for (f=1;f<=Nfleet;f++)
        {
          tempvec_l.initialize();
          for (y=Bmark_Yr(3);y<=Bmark_Yr(4);y++) {tempvec_l+=sel_l(y,f,gg);}
          sel_l(styr-3,f,gg)=tempvec_l/temp;

          tempvec_l.initialize();
          for (y=Bmark_Yr(3);y<=Bmark_Yr(4);y++) {tempvec_l+=sel_l_r(y,f,gg);}
          sel_l_r(styr-3,f,gg)=tempvec_l/temp;

          tempvec_l.initialize();
          for (y=Bmark_Yr(3);y<=Bmark_Yr(4);y++) {tempvec_l+=discmort2(y,f,gg);}
          discmort2(styr-3,f,gg)=tempvec_l/temp;

          tempvec_a.initialize();
          for (y=Bmark_Yr(3);y<=Bmark_Yr(4);y++) {tempvec_a+=sel_a(y,f,gg);}
          sel_a(styr-3,f,gg)=tempvec_a/temp;
        }

    //  set-up relative F among fleets and seasons
        if(Bmark_RelF_Basis==1)  // set allocation according to range of years
        {
          temp=0.0;
          Bmark_RelF_Use.initialize();
          for (y=Bmark_Yr(5);y<=Bmark_Yr(6);y++)
          for (f=1;f<=Nfleet;f++)
          for (s=1;s<=nseas;s++)
          {
            t=styr+(y-styr)*nseas+s-1;
            Bmark_RelF_Use(s,f)+=Hrate(f,t);
          }
          temp=sum(Bmark_RelF_Use);
          if(temp==0.0)
          {
            Bmark_RelF_Use(1,1)=1.0;
          }
          else
          {
          Bmark_RelF_Use/=temp;
          }
        }
        else  // Bmark_RelF_Basis==2 so set same as forecast
        {
          Bmark_RelF_Use=Fcast_RelF_Use;
        }
      }  //  end being in a phase for these calcs
    }  //  end getting quantities for benchmarks


//  SS_Label_Info_7.6 #If sdphase or mcevalphase, do benchmarks and forecast and derived quantities
    if( (sd_phase() || mceval_phase()) && (initial_params::mc_phase==0))
    {

//  SS_Label_Info_7.6.1 #Call fxn Get_Benchmarks()
      if(Do_Benchmark>0)
      {
        Get_Benchmarks();
        did_MSY=1;
      }
      else
      {Mgmt_quant(1)=SPB_virgin;}

      if(mceval_phase()==0) {show_MSY=1;}

//  SS_Label_Info_7.6.2 #Call fxn Get_Forecast()
      if(Do_Forecast>0)
      {
        report5<<"THIS FORECAST FOR PURPOSES OF STD REPORTING"<<endl;
        Get_Forecast();
        did_MSY=1;
      }

//  SS_Label_Info_7.7 #Call fxn Process_STDquant() to move calculated values into sd_containers
      Process_STDquant();
    }  // end of things to do in std_phase

//  SS_Label_Info_7.9 #Do screen output of procedure results from this iteration
    if(current_phase() <= max_phase+1) phase_output(current_phase())=value(obj_fun);
    if(rundetail>1)
      {
       if(Svy_N>0) cout<<" CPUE " <<surv_like<<endl;
       if(nobs_disc>0) cout<<" Disc " <<disc_like<<endl;
       if(nobs_mnwt>0) cout<<" MnWt " <<mnwt_like<<endl;
       if(Nobs_l_tot>0) cout<<" did lencomp obj_fun  " <<length_like_tot<<endl;
       if(Nobs_a_tot>0) cout<<" AGE  " <<age_like_tot<<endl;
       if(nobs_ms_tot>0) cout<<" L-at-A  " <<sizeage_like<<endl;
       if(SzFreq_Nmeth>0) cout<<" sizefreq "<<SzFreq_like<<endl;
       if(Do_TG>0) cout<<" TG-fleetcomp "<<TG_like1<<endl<<" TG-negbin "<<TG_like2<<endl;
       cout<<" Recr " <<recr_like<<endl;
       cout<<" Parm_Priors " <<parm_like<<endl;
       cout<<" MGParm_devs " <<MGparm_dev_like<<" "<<" seldevs: "<<selparm_dev_like<<endl;
       cout<<" SoftBound "<<SoftBoundPen<<endl;
       cout<<" F_ballpark " <<F_ballpark_like<<endl;
       if(F_Method>1) {cout<<"Catch "<<catch_like;} else {cout<<"  crash "<<CrashPen;}
       cout<<" EQUL_catch " <<equ_catch_like<<endl;
      }
     if(rundetail>0)
     {
       temp=norm2(recdev(recdev_start,recdev_end));
       temp=sqrt((temp+0.0000001)/(double(recdev_end-recdev_start+1)));
     if(mcmc_counter==0 && mceval_counter==0)
     {cout<<current_phase()<<" "<<niter<<" -log(L): "<<obj_fun<<"  Spbio: "<<value(SPB_yr(styr))<<" "<<value(SPB_yr(endyr));}
     else if (mcmc_counter>0)
     {cout<<" MCMC: "<<mcmc_counter<<" -log(L): "<<obj_fun<<"  Spbio: "<<value(SPB_yr(styr))<<" "<<value(SPB_yr(endyr));}
     else if (mceval_counter>0)
     {cout<<" MCeval: "<<mceval_counter<<" -log(L): "<<obj_fun<<"  Spbio: "<<value(SPB_yr(styr))<<" "<<value(SPB_yr(endyr));}
       if(F_Method>1 && sum(catch_like)>0.01) {cout<<" cat "<<sum(catch_like);}
       else if (CrashPen>0.01) {cout<<"  crash "<<CrashPen;}
       cout<<endl;
     }

//  SS_Label_Info_7.10 #Write parameter values to ParmTrace
      if((Do_ParmTrace==1 && obj_fun<=last_objfun) || Do_ParmTrace==4)
      {
        ParmTrace<<current_phase()<<" "<<niter<<" "<<obj_fun<<" "<<obj_fun-last_objfun
        <<" "<<value(SPB_yr(styr))<<" "<<value(SPB_yr(endyr))<<" "<<biasadj(styr)<<" "<<max(biasadj)<<" "<<biasadj(endyr);
        for (j=1;j<=MGparm_PH.indexmax();j++)
        {
          if(MGparm_PH(j)>=0) {ParmTrace<<" "<<MGparm(j);}
        }
        if(MGparm_dev_PH>0 && N_MGparm_dev>0)
        {
          for (j=1;j<=N_MGparm_dev;j++)
          {ParmTrace<<MGparm_dev(j)<<" ";}
        }
        for (j=1;j<=SRvec_PH.indexmax();j++)
        {
          if(SRvec_PH(j)>=0) {ParmTrace<<" "<<SR_parm(j);}
        }
        if(recdev_cycle>0)
        {
          for (j=1;j<=recdev_cycle;j++)
          {
            if(recdev_cycle_PH(j)>=0) {ParmTrace<<" "<<recdev_cycle_parm(j);}
          }
        }
        if(recdev_early_PH>0) {ParmTrace<<" "<<recdev_early;}
        if(recdev_PH>0)
        {
          if(do_recdev==1) {ParmTrace<<" "<<recdev1;}
          if(do_recdev==2) {ParmTrace<<" "<<recdev2;}
        }
        if(Do_Forecast>0) ParmTrace<<Fcast_recruitments<<" ";
        if(Do_Forecast>0 && Do_Impl_Error>0) ParmTrace<<Fcast_impl_error<<" ";
        for (f=1;f<=N_init_F;f++)
        {
          if(init_F_PH(f)>0) {ParmTrace<<" "<<init_F(f);}
        }
        if(F_Method==2)    // continuous F
        {
          for (k=1;k<=N_Fparm;k++)
          {
            if(Fparm_PH(k)>0) {ParmTrace<<" "<<F_rate(k);}
          }
        }
        for (f=1;f<=Q_Npar;f++)
        {
          if(Q_parm_PH(f)>0) {ParmTrace<<" "<<Q_parm(f);}
        }
        for (k=1;k<=selparm_PH.indexmax();k++)
        {
          if(selparm_PH(k)>0) {ParmTrace<<" "<<selparm(k);}
        }
        if(selparm_dev_PH>0 && N_selparm_dev>0)
        {
          for (j=1;j<=N_selparm_dev;j++)
          {ParmTrace<<selparm_dev(j)<<" ";}
        }
        for (k=1;k<=TG_parm_PH.indexmax();k++)
        {
          if(TG_parm_PH(k)>0) {ParmTrace<<" "<<TG_parm(k);}
        }
        ParmTrace<<endl;
      }
      else if((Do_ParmTrace==2 && obj_fun<=last_objfun) || Do_ParmTrace==3)
      {
        ParmTrace<<current_phase()<<" "<<niter<<" "<<obj_fun<<" "<<obj_fun-last_objfun
        <<" "<<value(SPB_yr(styr))<<" "<<value(SPB_yr(endyr))<<" "<<biasadj(styr)<<" "<<max(biasadj)<<" "<<biasadj(endyr);
        ParmTrace<<" "<<MGparm<<" ";
        if(N_MGparm_dev>0)
        {
          for (j=1;j<=N_MGparm_dev;j++)
          {ParmTrace<<MGparm_dev(j);}
        }
        ParmTrace<<SR_parm<<" ";
        if(recdev_cycle>0) ParmTrace<<recdev_cycle_parm;
        if(recdev_do_early>0) ParmTrace<<recdev_early<<" ";
        if(do_recdev==1) {ParmTrace<<recdev1<<" ";}
        if(do_recdev==2) {ParmTrace<<recdev2<<" ";}
        if(Do_Forecast>0) ParmTrace<<Fcast_recruitments<<" "<<Fcast_impl_error<<" ";
        if(N_init_F>0) ParmTrace<<init_F<<" ";
        if(F_Method==2) ParmTrace<<F_rate<<" ";
        if(Q_Npar>0) ParmTrace<<Q_parm<<" ";
        ParmTrace<<selparm<<" ";
        if(N_selparm_dev>0)
        {
          for (j=1;j<=N_selparm_dev;j++)
          {ParmTrace<<selparm_dev(j)<<" ";}
        }
        if(Do_TG>0) ParmTrace<<TG_parm<<" ";
        ParmTrace<<endl;
      }
      if(obj_fun<=last_objfun) last_objfun=obj_fun;
     docheckup=0;  // turn off reporting to checkup.sso
//  SS_Label_Info_7.11 #Call fxn get_posteriors if in mceval_phase
     if(mceval_phase()) get_posteriors();
  }  //  end doing of the calculations

  if(mceval_phase() || initial_params::mc_phase==1)
  {
    No_Report=1;  //  flag to skip output reports after MCMC and McEVAL
  }
  }
//  SS_Label_Info_7.12 #End of PROCEDURE_SECTION
