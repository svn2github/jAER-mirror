/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.seebetter.ini.chips.davis;

import java.util.Observable;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.swing.JPanel;

import net.sf.jaer.biasgen.AddressedIPotArray;
import net.sf.jaer.biasgen.Pot;
import net.sf.jaer.biasgen.coarsefine.ShiftedSourceBiasCF;
import net.sf.jaer.chip.Chip;
import net.sf.jaer.hardwareinterface.HardwareInterfaceException;
import ch.unizh.ini.jaer.config.onchip.OnchipConfigBit;
import eu.seebetter.ini.chips.davis.imu.ImuControl;

/**
 * Base configuration for tower wafer Davis chips that use the Tower wafer bias
 * generator
 *
 * @author tobi
 */
public class DavisTowerBaseConfig extends DavisConfig {

	protected TowerOnChip6BitVDAC[] vdacs;

	public DavisTowerBaseConfig(Chip chip) {
		super(chip);
		// // port bits
		// addConfigValue(nChipReset);
		// addConfigValue(powerDown);
		// addConfigValue(runAdc);
		// addConfigValue(runCpld);
		//
		// // cpld shift register stuff
		// addConfigValue(exposureControlRegister);
		// addConfigValue(resSettle);
		// addConfigValue(rowSettle);
		// addConfigValue(colSettle);
		// addConfigValue(frameDelayControlRegister);
		// addConfigValue(nullSettle);
		//
		// addConfigValue(miscControlBits);
		//
		// // imu config values
		// addConfigValue(imu0PowerMgmtClkRegConfig);
		// addConfigValue(imu1DLPFConfig);
		// addConfigValue(imu2SamplerateDividerConfig);
		// addConfigValue(imu3GyroConfig);
		// addConfigValue(imu4AccelConfig);
		//
		// // masterbias
		// getMasterbias().setKPrimeNFet(55e-3f); // estimated from tox=42A, mu_n=670 cm^2/Vs // TODO fix for UMC18
		// process
		// getMasterbias().setMultiplier(4); // =45 correct for dvs320
		// getMasterbias().setWOverL(4.8f / 2.4f); // masterbias has nfet with w/l=2 at output
		// getMasterbias().addObserver(this); // changes to masterbias come back to update() here

		setPotArray(new AddressedIPotArray(this)); // garbage collect IPots added in super by making this new potArray

		vdacs = new TowerOnChip6BitVDAC[8];
		// TODO fix this code for actual vdacs
		int address = 0;
		// getPotArray().addPot(new TowerOnChip6BitVDAC(this, "", 0, 0, ""));
		getPotArray().addPot(
			new TowerOnChip6BitVDAC(this, "apsOverflowLevel", 0, 0,
				"Sets reset level gate voltage of APS reset FET to prevent overflow causing DVS events"));
		getPotArray().addPot(
			new TowerOnChip6BitVDAC(this, "ApsCas", 1, 0,
				"n-type cascode for protecting drain of DVS photoreceptor log feedback FET from APS transients"));
		getPotArray()
			.addPot(
				new TowerOnChip6BitVDAC(this, "ADC_RefHigh", 2, 0,
					"on-chip column-parallel APS ADC upper conversion limit"));
		getPotArray().addPot(
			new TowerOnChip6BitVDAC(this, "ADC_RefLow", 3, 0, "on-chip column-parallel APS ADC ADC lower limit"));
		getPotArray().addPot(
			new TowerOnChip6BitVDAC(this, "AdcTestVoltagexAI", 4, 0, "Voltage supply for testing the ADC"));
		getPotArray().addPot(new TowerOnChip6BitVDAC(this, "BlkV1", 5, 0, "unused"));
		getPotArray().addPot(new TowerOnChip6BitVDAC(this, "BlkV2", 6, 0, "unused"));
		getPotArray().addPot(new TowerOnChip6BitVDAC(this, "BlkV3", 7, 0, "unused"));

		try {
			// added from gdoc
			// https://docs.google.com/spreadsheet/ccc?key=0AuXeirzvZroNdHNLMWVldWVJdkdqNGNxOG5ZOFdXcHc#gid=6
			// private AddressedIPotCF diffOn, diffOff, refr, pr, sf, diff;
			addAIPot("LocalBufBn,n,normal,Local buffer bias"); // 8
			addAIPot("PadFollBn,n,normal,Follower-pad buffer bias current");// 9
			diff = addAIPot("DiffBn,n,normal,differencing amp");
			diffOn = addAIPot("OnBn,n,normal,DVS brighter threshold");
			diffOff = addAIPot("OffBn,n,normal,DVS darker threshold");
			addAIPot("PixInvBn,n,normal,Pixel request inversion static inverter bias");
			pr = addAIPot("PrBp,p,normal,Photoreceptor bias current");
			sf = addAIPot("PrSFBp,p,normal,Photoreceptor follower bias current (when used in pixel type)");
			refr = addAIPot("RefrBp,p,normal,DVS refractory period current");
			addAIPot("ReadoutBufBP,p,normal,APS readout OTA follower bias");
			addAIPot("ApsROSFBn,n,normal,APS readout source follower bias"); // 18
			addAIPot("ADCcompBp,p,normal,ADC comparator bias"); // 19
			addAIPot("ColSelLowBn,n,normal,Column arbiter request pull-down"); // 20
			addAIPot("DACBufBp,p,normal,Row request pull up"); // 21
			addAIPot("LcolTimeoutBn,n,normal,No column request timeout"); // 22
			addAIPot("AEPdBn,n,normal,Request encoder pulldown static current");
			addAIPot("AEPuXBp,p,normal,AER column pullup");
			addAIPot("AEPuYBp,p,normal,AER row pullup");
			addAIPot("IFRefrBn,n,normal,Bias calibration refractory period bias current"); // 26
			addAIPot("IFThrBn,n,normal,Bias calibration neuron threshold"); // 27
			addAIPot("Blk1P,p,normal,Ununsed P type"); // 28
			addAIPot("Blk2P,p,normal,Ununsed P type"); //
			addAIPot("Blk1N,n,normal,Ununsed N type"); //
			addAIPot("Blk2N,n,normal,Ununsed N type"); //
			addAIPot("Blk3N,n,normal,Ununsed N type"); //
			addAIPot("Blk4N,n,normal,Ununsed N type"); //
			addAIPot("biasBuffer,n,normal,special buffer bias "); // address 34

			// shifted sources
			ssn = new ShiftedSourceBiasCF(this);
			ssn.setSex(Pot.Sex.N);
			ssn.setName("SSN");
			ssn.setTooltipString("n-type shifted source that generates a regulated voltage near ground");
			ssn.addObserver(this);
			ssn.setAddress(35);

			ssp = new ShiftedSourceBiasCF(this);
			ssp.setSex(Pot.Sex.P);
			ssp.setName("SSP");
			ssp.setTooltipString("p-type shifted source that generates a regulated voltage near Vdd");
			ssp.addObserver(this);
			ssp.setAddress(36);

			ssBiases[1] = ssn;
			ssBiases[0] = ssp;

			// old, from SBRet10/20/21
			// diff = addAIPot("DiffBn,n,normal,differencing amp");
			// diffOn = addAIPot("OnBn,n,normal,DVS brighter threshold");
			// diffOff = addAIPot("OffBn,n,normal,DVS darker threshold");
			// addAIPot("ApsCasEpc,p,cascode,cascode between APS und DVS");
			// addAIPot("DiffCasBnc,n,cascode,differentiator cascode bias");
			// addAIPot("ApsROSFBn,n,normal,APS readout source follower bias");
			// addAIPot("LocalBufBn,n,normal,Local buffer bias"); // TODO what's this?
			// addAIPot("PixInvBn,n,normal,Pixel request inversion static inverter bias");
			// pr = addAIPot("PrBp,p,normal,Photoreceptor bias current");
			// sf = addAIPot("PrSFBp,p,normal,Photoreceptor follower bias current (when used in pixel type)");
			// refr = addAIPot("RefrBp,p,normal,DVS refractory period current");
			// addAIPot("AEPdBn,n,normal,Request encoder pulldown static current");
			// addAIPot("LcolTimeoutBn,n,normal,No column request timeout");
			// addAIPot("AEPuXBp,p,normal,AER column pullup");
			// addAIPot("AEPuYBp,p,normal,AER row pullup");
			// addAIPot("IFThrBn,n,normal,Integrate and fire intensity neuron threshold");
			// addAIPot("IFRefrBn,n,normal,Integrate and fire intensity neuron refractory period bias current");
			// addAIPot("PadFollBn,n,normal,Follower-pad buffer bias current");
			// addAIPot("apsOverflowLevel,n,normal,special overflow level bias ");
			// addAIPot("biasBuffer,n,normal,special buffer bias ");
		}
		catch (Exception e) {
			throw new Error(e.toString());
		}

		// graphicOptions
		videoControl = new VideoControl();
		videoControl.addObserver(this);

		// on-chip configuration chain
		chipConfigChain = new DavisTowerBaseChipConfigChain(chip);
		chipConfigChain.addObserver(this);

		// control of log readout
		apsReadoutControl = new ApsReadoutControl();

		// imuControl
		imuControl = new ImuControl(this);

		setBatchEditOccurring(true);
		loadPreferences();
		setBatchEditOccurring(false);
		try {
			sendConfiguration(this);
		}
		catch (HardwareInterfaceException ex) {
			Logger.getLogger(DAVIS240BaseCamera.class.getName()).log(Level.SEVERE, null, ex);
		}
	}

	@Override
	public JPanel buildControlPanel() {
		return super.buildControlPanel(); // To change body of generated methods, choose Tools | Templates.
	}

	@Override
	public synchronized void update(Observable observable, Object object) {
		super.update(observable, object);
		try {
			if (observable instanceof TowerOnChip6BitVDAC) {
				sendOnChipConfig();
			}
		}
		catch (HardwareInterfaceException e) {
			log.warning("On update() caught " + e.toString());
		}

	}

	public class DavisTowerBaseChipConfigChain extends DavisChipConfigChain {
		OnchipConfigBit selectGrayCounter = new OnchipConfigBit(chip, "SelectGrayCounter", 7,
			"Select internal gray counter, if disabled, external gray code is used.", true);
		OnchipConfigBit testADC = new OnchipConfigBit(chip, "TestADC", 8,
			"Pass ADC Test Voltage to internal ADC instead of pixel voltage.", false);

		public DavisTowerBaseChipConfigChain(Chip chip) {
			super(chip);

			configBits[7] = selectGrayCounter;
			configBits[7].addObserver(this);
			configBits[8] = testADC;
			configBits[8].addObserver(this);
		}
	}
}
