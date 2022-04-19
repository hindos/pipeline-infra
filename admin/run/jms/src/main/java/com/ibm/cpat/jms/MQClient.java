package com.ibm.cpat.jms;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSProducer;
import javax.jms.Queue;

public class MQClient {

    private final Queue queue;
    private final JMSContext context;

    public MQClient(JMSContext context, String queueName) {
        this.context = context;
        queue = context.createQueue("queue:///" + queueName);
    }

    public void send(String message) {
        JMSProducer producer = context.createProducer();
        producer.send(queue, message);
    }

    public String receive(int timeOut) {
        JMSConsumer consumer = context.createConsumer(queue);
        return consumer.receiveBody(String.class, timeOut);
    }
}
