package com.ibm.cpat.jms;

import javax.jms.ConnectionFactory;
import javax.jms.JMSContext;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;

public class Driver {

    public static void main(String[] args) throws IOException {
        setUpProperties();

        String qmName = Optional.ofNullable(System.getenv("QM_NAME"))
                .orElseThrow(() -> new RuntimeException("Specify QM_NAME"));

        String host = Optional.ofNullable(System.getenv("HOST"))
                .orElseThrow(() -> new RuntimeException("Specify HOST"));

        String port = Optional.ofNullable(System.getenv("PORT"))
                .orElseThrow(() -> new RuntimeException("Specify PORT"));

        String svrconn = Optional.ofNullable(System.getenv("SVRCONN"))
                .orElseThrow(() -> new RuntimeException("Specify SVRCONN"));

        ConnectionFactory cf = new JMSConnectionFactoryBuilder(qmName)
                .withHost(host)
                .withPort(Integer.parseInt(port))
                .withUserAuthentication("app", "app")
                .withSslCipherSuite("TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384")
                .withChannel(svrconn)
                .build();

        String queueName = Optional.ofNullable(System.getenv("QUEUE_NAME"))
                .orElseThrow(() -> new RuntimeException("Specify QUEUE_NAME"));

        Path payloadPath = Paths.get(Optional.ofNullable(System.getenv("PAYLOAD_PATH"))
                .orElseThrow(() -> new RuntimeException("Specify PAYLOAD_PATH")));
        String payload = new String(Files.readAllBytes(payloadPath));

        send(cf, queueName, payload);

    }

    private static void setUpProperties() {
        String keystorePath = Optional.ofNullable(System.getenv("JKS_KEYSTORE_PATH"))
                .orElseThrow(() -> new RuntimeException("Specify JKS_KEYSTORE_PATH"));
        System.setProperty("javax.net.ssl.keyStore", keystorePath);
        System.setProperty("javax.net.ssl.keyStorePassword", "passw0rd");

        String truststorePath = Optional.ofNullable(System.getenv("JKS_TRUSTSTORE_PATH"))
                .orElseThrow(() -> new RuntimeException("Specify JKS_TRUSTSTORE_PATH"));
        System.setProperty("javax.net.ssl.trustStore", truststorePath);
        System.setProperty("javax.net.ssl.trustStorePassword", "passw0rd");

        System.setProperty("com.ibm.mq.cfg.useIBMCipherMappings", "false");
    }

    private static void send(ConnectionFactory cf, String queueName, String message) {
        try (JMSContext context = cf.createContext()) {
            MQClient mqClient = new MQClient(context, queueName);
            mqClient.send(message);
        }
    }
}
