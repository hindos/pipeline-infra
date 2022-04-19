package com.ibm.cpat.jms;

import com.ibm.msg.client.jms.JmsConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;
import org.junit.jupiter.api.Test;

import javax.jms.ConnectionFactory;
import javax.jms.JMSException;

import static org.assertj.core.api.Assertions.assertThat;

public class JMSConnectionFactoryBuilderTest {

    @Test
    void testBuild() {
        ConnectionFactory cf = new JMSConnectionFactoryBuilder("QM1")
                .withHost("wombat")
                .withPort(2424)
                .withChannel("DEV.APP.SVRCONN")
                .withUserAuthentication("app", "password")
                .withSslCipherSuite("TLS_RSA_WITH_AES_128_CBC_SHA256")
                .build();

        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.WMQ_HOST_NAME)).isEqualTo("wombat"));
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getIntProperty(c, WMQConstants.WMQ_PORT)).isEqualTo(2424));
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.WMQ_CHANNEL)).isEqualTo("DEV.APP.SVRCONN"));
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.WMQ_QUEUE_MANAGER)).isEqualTo("QM1"));
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.WMQ_QUEUE_MANAGER)).isEqualTo("QM1"));
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getBooleanProperty(c, WMQConstants.USER_AUTHENTICATION_MQCSP)).isTrue());
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.USERID)).isEqualTo("app"));
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.PASSWORD)).isEqualTo("password"));
        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.WMQ_SSL_CIPHER_SUITE))
                        .isEqualTo("TLS_RSA_WITH_AES_128_CBC_SHA256"));
    }

    private boolean getBooleanProperty(JmsConnectionFactory cf, String name) {
        try {
            return cf.getBooleanProperty(name);
        } catch (JMSException ex) {
            throw new AssertionError(ex.getMessage());
        }
    }

    private String getStringProperty(JmsConnectionFactory cf, String name) {
        try {
            return cf.getStringProperty(name);
        } catch (JMSException ex) {
            throw new AssertionError(ex.getMessage());
        }
    }

    private int getIntProperty(JmsConnectionFactory cf, String name) {
        try {
            return cf.getIntProperty(name);
        } catch (JMSException ex) {
            throw new AssertionError(ex.getMessage());
        }
    }


    @Test
    void testBuilder_withUnspecifiedHostname() {
        ConnectionFactory cf = new JMSConnectionFactoryBuilder("QM1").build();

        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.WMQ_HOST_NAME)).isEqualTo("localhost"));
    }

    @Test
    void testBuilder_withUnspecifiedPort() {
        ConnectionFactory cf = new JMSConnectionFactoryBuilder("QM1").build();

        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getIntProperty(c, WMQConstants.WMQ_PORT)).isEqualTo(1414));
    }

    @Test
    void testBuilder_withUnspecifiedChannel() {
        ConnectionFactory cf = new JMSConnectionFactoryBuilder("QM1").build();

        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getStringProperty(c, WMQConstants.WMQ_CHANNEL)).isEqualTo("SYSTEM.DEF.SVRCONN"));
    }

    @Test
    void testBuilder_withUnspecifiedConnectionMode() {
        ConnectionFactory cf = new JMSConnectionFactoryBuilder("QM1").build();

        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getIntProperty(c, WMQConstants.WMQ_CONNECTION_MODE))
                        .isEqualTo(WMQConstants.WMQ_CM_CLIENT));
    }

    @Test
    void testBuilder_withUnspecifiedUserAuthentication() throws Exception {
        ConnectionFactory cf = new JMSConnectionFactoryBuilder("QM1").build();

        assertThat(cf).isInstanceOfSatisfying(JmsConnectionFactory.class,
                c -> assertThat(getBooleanProperty(c, WMQConstants.USER_AUTHENTICATION_MQCSP))
                        .isFalse());
    }

}
