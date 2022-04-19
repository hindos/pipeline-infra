package com.ibm.cpat.jms;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSProducer;
import javax.jms.Queue;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

public class MQClientTest {

    @Mock
    private JMSContext context;

    @Mock
    private Queue destination;
    private MQClient mqClient;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.initMocks(this);

        String queueName = "DEV.QUEUE.1";
        when(context.createQueue("queue:///" + queueName)).thenReturn(destination);
        mqClient = new MQClient(context, "DEV.QUEUE.1");
    }

    @Test
    void testSend() {
        JMSProducer producer = mock(JMSProducer.class);
        when(context.createProducer()).thenReturn(producer);

        mqClient.send("hello, world!");

        verify(producer).send(destination, "hello, world!");
    }

    @Test
    void testReceive() {
        JMSConsumer consumer = mock(JMSConsumer.class);
        when(context.createConsumer(destination)).thenReturn(consumer);
        when(consumer.receiveBody(String.class, 1500)).thenReturn("hello, world!");

        String message = mqClient.receive(1500);

        assertThat(message).isEqualTo("hello, world!");
    }

}
