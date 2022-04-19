package com.ibm.cpat.jms;

import com.ibm.msg.client.jms.JmsConnectionFactory;
import com.ibm.msg.client.jms.JmsFactoryFactory;
import com.ibm.msg.client.wmq.WMQConstants;

import javax.jms.ConnectionFactory;
import javax.jms.JMSException;

public class JMSConnectionFactoryBuilder {
    private final String queueManager;

    private String hostname;
    private int port = -1;
    private String channel;
    private boolean userAuthentication;
    private String userId;
    private String password;
    private String sslCiperSuite;

    public JMSConnectionFactoryBuilder(String queueManager) {
        this.queueManager = queueManager;
    }

    public JMSConnectionFactoryBuilder withHost(String hostname) {
        this.hostname = hostname;
        return this;
    }

    public JMSConnectionFactoryBuilder withPort(int port) {
        this.port = port;
        return this;
    }

    public ConnectionFactory build() {
        try {
            JmsFactoryFactory ff = JmsFactoryFactory.getInstance(WMQConstants.WMQ_PROVIDER);
            JmsConnectionFactory cf = ff.createConnectionFactory();

            setHostname(cf);
            setPort(cf);
            setChannel(cf);
            setConnectionMode(cf);
            setQueueManager(cf);
            setUserAuthentication(cf);
            setCipherSuite(cf);

            return cf;
        } catch (JMSException ex) {
            throw new RuntimeException(ex);
        }
    }

    private void setCipherSuite(JmsConnectionFactory cf) throws JMSException {
        if (sslCiperSuite != null) {
            cf.setStringProperty(WMQConstants.WMQ_SSL_CIPHER_SUITE, sslCiperSuite);

        }
    }

    private void setUserAuthentication(JmsConnectionFactory cf) throws JMSException {
        if (userAuthentication) {
            cf.setBooleanProperty(WMQConstants.USER_AUTHENTICATION_MQCSP, true);
            cf.setStringProperty(WMQConstants.USERID, this.userId);
            cf.setStringProperty(WMQConstants.PASSWORD, this.password);
        }
    }

    private void setQueueManager(JmsConnectionFactory cf) throws JMSException {
        cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, queueManager);
    }

    private void setConnectionMode(JmsConnectionFactory cf) throws JMSException {
        cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_CLIENT);
    }

    private void setChannel(JmsConnectionFactory cf) throws JMSException {
        if (channel != null) {
            cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
        }
    }

    private void setPort(JmsConnectionFactory cf) throws JMSException {
        if (port != -1) {
            cf.setIntProperty(WMQConstants.WMQ_PORT, port);
        }
    }

    private void setHostname(JmsConnectionFactory cf) throws JMSException {
        if (hostname != null) {
            cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
        }
    }

    public JMSConnectionFactoryBuilder withChannel(String channel) {
        this.channel = channel;
        return this;
    }

    public JMSConnectionFactoryBuilder withUserAuthentication(String userId, String password) {
        this.userAuthentication = true;
        this.userId = userId;
        this.password = password;
        return this;
    }

    public JMSConnectionFactoryBuilder withSslCipherSuite(String sslCipherSuite) {
        this.sslCiperSuite = sslCipherSuite;
        return this;
    }
}
