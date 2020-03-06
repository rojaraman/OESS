#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 1;

use XML::LibXML;

use OESS::MPLS::Device::Juniper::MX;


# Purpose:
#
# Validate correct generation of L2CCC L2Connection template.


my $exp_xml = '<configuration>
  <groups operation="delete"><name>OESS</name></groups>
  <groups>
    <name>OESS</name>
    <interfaces>
      <interface>
        <name>ge-0/0/1</name>
        <unit>
          <name>2004</name>
          <description>OESS-L2CCC-3012</description>
          <family>
            <ccc><mtu>9000</mtu></ccc>
          </family>
          <encapsulation>vlan-ccc</encapsulation>
          <vlan-tags>
            <outer>2004</outer>
            <inner>30</inner>
          </vlan-tags>
          <output-vlan-map>
            <swap/>
          </output-vlan-map>
        </unit>
      </interface>
      <interface>
        <name>ge-0/0/2</name>
        <unit>
          <name>2004</name>
          <description>OESS-L2CCC-3012</description>
          <encapsulation>vlan-ccc</encapsulation>
          <vlan-id>2004</vlan-id>
          <output-vlan-map>
            <swap/>
          </output-vlan-map>
        </unit>
      </interface>
    </interfaces>

    <class-of-service>
      <interfaces>
        <interface>
          <name>ge-0/0/1</name>
          <unit>
            <name>2004</name>
            <shaping-rate><rate>50m</rate></shaping-rate>
          </unit>
        </interface>
      </interfaces>
    </class-of-service>

    <protocols>
      <mpls>
        <label-switched-path>
          <name>OESS-L2CCC-100-200-LSP-3012</name>
          <apply-groups>L2CCC-LSP-ATTRIBUTES</apply-groups>
          <to/>
          <primary>
            <name>OESS-L2CCC-100-200-LSP-3012-PRIMARY</name>
          </primary>
          <secondary>
            <name>OESS-L2CCC-100-200-LSP-3012-TERTIARY</name>
            <standby/>
          </secondary>
        </label-switched-path>
        <path>
          <name>OESS-L2CCC-100-200-LSP-3012-PRIMARY</name>
          <path-list>
            <name>192.186.1.150</name>
            <strict/>
          </path-list>
          <path-list>
            <name>192.168.1.200</name>
            <strict/>
          </path-list>
        </path>
        <path>
          <name>OESS-L2CCC-100-200-LSP-3012-TERTIARY</name>
        </path>
      </mpls>
      <connections>
        <remote-interface-switch>
          <name>OESS-L2CCC-3012</name>
          <interface>ge-0/0/1.2004</interface>
          <interface>ge-0/0/2.2004</interface>
          <transmit-lsp>OESS-L2CCC-100-200-LSP-3012</transmit-lsp>
          <receive-lsp>OESS-L2CCC-200-100-LSP-3012</receive-lsp>
        </remote-interface-switch>
      </connections>
    </protocols>
  </groups>
  <apply-groups>OESS</apply-groups>
</configuration>';

my $device = OESS::MPLS::Device::Juniper::MX->new(
    config => '/etc/oess/database.xml',
    loopback_addr => '127.0.0.1',
    mgmt_addr => '127.0.0.1',
    name => 'vmx-r0.testlab.grnoc.iu.edu',
    node_id => 1
);
my $conf = $device->xml_configuration(
    [{
        circuit_name => 'circuit',
        interfaces => [
            {
                interface => 'ge-0/0/1',
                unit => 2004,
                tag => 2004,
                inner_tag => 30, # CHECK: QinQ
                bandwidth => 50, # CHECK: class-of-service added
                mtu => 9000      # CHECK: family > ccc > mtu added
            },
            {
                interface => 'ge-0/0/2',
                unit => 2004,
                tag => 2004,
                bandwidth => 0,  # CHECK: class-of-service omitted
                mtu => 0         # CHECK: family > ccc > mtu omitted
            }
        ],
        paths => [
            {
                name => 'PRIMARY',
                dest_node => 200,
                mpls_path_type => 'strict',
                path => [
                    '192.186.1.150',
                    '192.168.1.200'
                ]
            },
            {
                name => 'TERTIARY',
                dest_node => 200,
                mpls_path_type => 'loose'
            }
        ],
        circuit_id => 3012,
        site_id => 1,
        state => 'active',
        dest => '192.168.1.200',
        a_side => 100,
        ckt_type => 'L2CCC'
    }],
    [],
    '<groups operation="delete"><name>OESS</name></groups>'
);

# Load expected and generated XML and convert to string minus
# whitespace for easy comparision.
my $exml = XML::LibXML->load_xml(string => $exp_xml, {no_blanks => 1});
my $gxml = XML::LibXML->load_xml(string => $conf, {no_blanks => 1});

my $e = $exml->toString;
my $g = $gxml->toString;

ok($e eq $g, 'Got expected XMl');
if ($e ne $g) {
    warn Dumper($e);
    warn Dumper($g);
}
