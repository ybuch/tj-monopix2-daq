#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import collections
import os
import time

import pkg_resources
import yaml
from basil.dut import Dut

from tjmonopix2.system import logger
from tjmonopix2.system.tjmono2_rx import tjmono2_rx

VERSION = pkg_resources.get_distribution("tjmonopix2").version


class BDAQ53(Dut):
    '''
    Main class for BDAQ53 readout system
    '''
    def __init__(self, conf=None, bench_config=None):
        self.log = logger.setup_main_logger()
        self.proj_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.configuration = {}
        self.board_version = 'bdaq53'

        try:
            if bench_config is None:
                bench_config = os.path.join(self.proj_dir, 'testbench.yaml')
            with open(bench_config) as f:
                self.configuration = yaml.full_load(f)
        except TypeError:
            self.configuration = bench_config

        self.receivers = ['rx0']

        if not conf:
            conf = os.path.join(self.proj_dir, 'system' + os.sep + 'bdaq53.yaml')
        self.log.debug("Loading configuration file from %s" % conf)

        # Flag indicating of tlu module is enabled.
        self.tlu_module_enabled = False

        super(BDAQ53, self).__init__(conf)

    def init(self, **kwargs):
        super(BDAQ53, self).init()

        self.fw_version, self.board_version = self['system'].get_daq_version()
        self.log.success('Found board %s running firmware version %s' % (self.board_version, self.fw_version))

        if self.fw_version != VERSION.split('.')[0] + '.' + VERSION.split('.')[1]:  # Compare only the first two blocks
            raise Exception("Firmware version (%s) is different than software version (%s)! Please update." % (self.fw_version, VERSION))

        # Initialize readout (only one chip supported at the moment)
        self.rx_channels = {}
        self.rx_channels['rx0'] = tjmono2_rx(self['intf'], {'name': 'rx', 'type': 'tjmonopix2.tjmono2_rx', 'interface': 'intf',
                                                            'base_addr': 0x0200})
        self.rx_channels['rx0'].init()

        # self.rx_lanes = {}
        # for recv in self.receivers:
        #     t_rx_lanes = self.rx_channels[recv].get_rx_config()
        #     self.rx_lanes[recv] = t_rx_lanes

        # Configure cmd encoder
        self.set_cmd_clk(frequency=160.0)
        self['cmd'].reset()
        time.sleep(0.1)

        # # Wait for the chip (model) PLL to lock before establishing a link
        # if self.board_version == 'SIMULATION':
        #     for _ in range(100):
        #         self.rx_channels['rx0'].get_rx_ready()

    def set_cmd_clk(self, frequency=160.0, force=False):
        if self.board_version in {'BDAQ53', 'MIO3'}:
            if self['system']['SI570_IS_CONFIGURED'] == 0 or force is True:
                from basil.HL import si570
                si570_conf = {'name': 'si570', 'type': 'si570', 'interface': 'intf', 'base_addr': 0xba, 'init': {'frequency': frequency}}
                clk_gen = si570.si570(self['i2c'], si570_conf)
                self['cmd'].set_output_en(False)
                for receiver in self.receivers:
                    self.rx_channels[receiver].reset()
                time.sleep(0.1)
                clk_gen.init()
                time.sleep(0.1)
                self['cmd'].set_output_en(True)
                self['system']['SI570_IS_CONFIGURED'] = 1
            else:
                self.log.info('Si570 oscillator is already configured')
        elif self.board_version == 'SIMULATION':
            pass

    def get_chips_cfgs(self):
        module_cfgs = {k: v for k, v in self.configuration['modules'].items() if 'identifier' in v.keys()}
        chip_cfgs = []
        for mod_cfg in module_cfgs.values():
            for k, v in mod_cfg.items():
                if isinstance(v, collections.abc.Mapping) and 'chip_sn' in v:  # Detect chips defined in testbench by the definition of a chip serial number
                    chip_cfgs.append(v)
        return chip_cfgs

    def set_LEMO_MUX(self, connector='LEMO_MUX_TX0', value=0):
        '''
        Sets the multiplexer in order to select which signal is routed to LEMO ports. So far only used
        for LEMO_TX ports.

        Parameters
        ----------
        connector : string
            Name of the LEMO connector. Possible names: LEMO_MUX_TX1, LEMO_MUX_TX0
        value : int
            Value specifying the multiplexer state. Default is 0.
            LEMO_TX_0: not used (3), not used (2), CMD_LOOP_START_PULSE (1), RJ45_CLK (0)
            LEMO_TX_1: not used (3), not used (2), not used (1), RJ45_BUSY (0)
        '''

        # TODO:  LEMO_MUX_RX1 and LEMO_MUX_RX0 not yet used
        # According to FW. None means not used.
        lemo_tx0_signals = ['RJ45_CLK', 'CMD_LOOP_START_PULSE', None, None]
        lemo_tx1_signals = ['RJ45_BUSY', None, None, None]
        if connector in ('LEMO_MUX_TX1', 'LEMO_MUX_TX0') and value in range(4):
            self['DAQ_CONTROL'][connector] = value
            self['DAQ_CONTROL'].write()
            if 'TX0' in connector:
                signal = lemo_tx0_signals[value]
            if 'TX1' in connector:
                signal = lemo_tx1_signals[value]
            self.log.info('%s set to %s (%s)' % (connector, value, signal))
        else:
            self.log.error('%s or %s are invalid' % (connector, value))

    def set_chip_type(self):
        ''' Defines chip type ITkPixV1-like '''
        self['cmd'].set_chip_type(1)

    # def enable_auto_sync(self):
    #     '''Enables automatic sending of sync commands'''
    #     self['cmd'].set_auto_sync(1)

    # def disable_auto_sync(self):
    #     '''Disables automatic sending of sync commands'''
    #     self['cmd'].set_auto_sync(0)

    def configure_tdc_module(self):
        self.log.info('Configuring TDC module')
        self['tdc'].EN_WRITE_TIMESTAMP = self.configuration['TDC'].get('EN_WRITE_TIMESTAMP', 1)
        self['tdc'].EN_TRIGGER_DIST = self.configuration['TDC'].get('EN_TRIGGER_DIST', 1)
        self['tdc'].EN_NO_WRITE_TRIG_ERR = self.configuration['TDC'].get('EN_NO_WRITE_TRIG_ERR', 1)
        self['tdc'].EN_INVERT_TDC = self.configuration['TDC'].get('EN_INVERT_TDC', 0)
        self['tdc'].EN_INVERT_TRIGGER = self.configuration['TDC'].get('EN_INVERT_TRIGGER', 0)

    def enable_tdc_module(self):
        self['tdc'].ENABLE = 1

    def disable_tdc_module(self):
        self['tdc'].ENABLE = 0

    def enable_tlu_module(self):
        self['tlu']['TRIGGER_ENABLE'] = True
        self.tlu_module_enabled = True

    def disable_tlu_module(self):
        self['tlu']['TRIGGER_ENABLE'] = False
        self.tlu_module_enabled = False

    def get_trigger_counter(self):
        return self['tlu']['TRIGGER_COUNTER']

    def set_trigger_data_delay(self, trigger_data_delay):
        self['tlu']['TRIGGER_DATA_DELAY'] = trigger_data_delay

    def configure_tlu_module(self, max_triggers=False):
        self.log.info('Configuring TLU module...')
        self['tlu']['RESET'] = 1    # Reset first TLU module
        for key, value in self.configuration['TLU'].items():    # Set specified registers
            self['tlu'][key] = value
        self['tlu']['TRIGGER_COUNTER'] = 0

        if max_triggers:
            self['tlu']['MAX_TRIGGERS'] = int(max_triggers)  # Set maximum number of triggers
        else:
            self['tlu']['MAX_TRIGGERS'] = 0  # unlimited number of triggers

    def get_tlu_erros(self):
        return (self['tlu']['TRIGGER_LOW_TIMEOUT_ERROR_COUNTER'], self['tlu']['TLU_TRIGGER_ACCEPT_ERROR_COUNTER'])

    def configure_tlu_veto_pulse(self, veto_length):
        # configures pulse for veto of new triggers
        self['tlu_veto'].set_en(True)
        self['tlu_veto'].set_width(1)
        self['tlu_veto'].set_delay(veto_length)
        self['tlu_veto'].set_repeat(1)

    def configure_cmd_loop_start_pulse(self, width=8, delay=140):
        self['pulser_cmd_start_loop'].set_en(True)
        self['pulser_cmd_start_loop'].set_width(width)
        self['pulser_cmd_start_loop'].set_delay(delay)
        self['pulser_cmd_start_loop'].set_repeat(1)

    def reset_fifo(self):
        self['FIFO']['RESET'] = 0

    # def set_timestamp(self, src="rx0"):
    #     self["timestamp_{}".format(src)].reset()
    #     self["timestamp_{}".format(src)]["EXT_TIMESTAMP"] = True
    #     if src == "rx0":
    #         self["timestamp_rx1"]["ENABLE_TRAILING"] = 0
    #         self["timestamp_rx1"]["ENABLE"] = 1
    #     elif src == "hitor":
    #         self["timestamp_hitor"]["ENABLE_TRAILING"] = 1
    #         self["timestamp_hitor"]["ENABLE"] = 1
    #     elif src == "inj":
    #         self["timestamp_inj"]["ENABLE"] = 1

    #     logging.info("Set timestamp: src={}".format(src))

    # def stop_timestamp(self, src="rx0"):
    #     self["timestamp_{}".format(src)]["ENABLE"] = 0
    #     lost_cnt = self["timestamp_{}".format(src)]["LOST_COUNT"]
    #     if lost_cnt != 0:
    #         logging.warn("Stop timestamp: src={} lost_cnt={:d}".format(src, lost_cnt))
    #     return lost_cnt
