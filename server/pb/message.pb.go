// Code generated by protoc-gen-go. DO NOT EDIT.
// source: message.proto

package pb

import (
	fmt "fmt"
	proto "github.com/golang/protobuf/proto"
	_ "github.com/telenordigital/nbiot-e2e/server/pb/nanopb/generator/proto"
	math "math"
)

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// This is a compile-time assertion to ensure that this generated file
// is compatible with the proto package it is being compiled against.
// A compilation error at this line likely means your copy of the
// proto package needs to be updated.
const _ = proto.ProtoPackageIsVersion2 // please upgrade the proto package

type Message struct {
	// Types that are valid to be assigned to Message:
	//	*Message_PingMessage
	Message              isMessage_Message `protobuf_oneof:"message"`
	XXX_NoUnkeyedLiteral struct{}          `json:"-"`
	XXX_unrecognized     []byte            `json:"-"`
	XXX_sizecache        int32             `json:"-"`
}

func (m *Message) Reset()         { *m = Message{} }
func (m *Message) String() string { return proto.CompactTextString(m) }
func (*Message) ProtoMessage()    {}
func (*Message) Descriptor() ([]byte, []int) {
	return fileDescriptor_33c57e4bae7b9afd, []int{0}
}

func (m *Message) XXX_Unmarshal(b []byte) error {
	return xxx_messageInfo_Message.Unmarshal(m, b)
}
func (m *Message) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	return xxx_messageInfo_Message.Marshal(b, m, deterministic)
}
func (m *Message) XXX_Merge(src proto.Message) {
	xxx_messageInfo_Message.Merge(m, src)
}
func (m *Message) XXX_Size() int {
	return xxx_messageInfo_Message.Size(m)
}
func (m *Message) XXX_DiscardUnknown() {
	xxx_messageInfo_Message.DiscardUnknown(m)
}

var xxx_messageInfo_Message proto.InternalMessageInfo

type isMessage_Message interface {
	isMessage_Message()
}

type Message_PingMessage struct {
	PingMessage *PingMessage `protobuf:"bytes,1,opt,name=ping_message,json=pingMessage,proto3,oneof"`
}

func (*Message_PingMessage) isMessage_Message() {}

func (m *Message) GetMessage() isMessage_Message {
	if m != nil {
		return m.Message
	}
	return nil
}

func (m *Message) GetPingMessage() *PingMessage {
	if x, ok := m.GetMessage().(*Message_PingMessage); ok {
		return x.PingMessage
	}
	return nil
}

// XXX_OneofFuncs is for the internal use of the proto package.
func (*Message) XXX_OneofFuncs() (func(msg proto.Message, b *proto.Buffer) error, func(msg proto.Message, tag, wire int, b *proto.Buffer) (bool, error), func(msg proto.Message) (n int), []interface{}) {
	return _Message_OneofMarshaler, _Message_OneofUnmarshaler, _Message_OneofSizer, []interface{}{
		(*Message_PingMessage)(nil),
	}
}

func _Message_OneofMarshaler(msg proto.Message, b *proto.Buffer) error {
	m := msg.(*Message)
	// message
	switch x := m.Message.(type) {
	case *Message_PingMessage:
		b.EncodeVarint(1<<3 | proto.WireBytes)
		if err := b.EncodeMessage(x.PingMessage); err != nil {
			return err
		}
	case nil:
	default:
		return fmt.Errorf("Message.Message has unexpected type %T", x)
	}
	return nil
}

func _Message_OneofUnmarshaler(msg proto.Message, tag, wire int, b *proto.Buffer) (bool, error) {
	m := msg.(*Message)
	switch tag {
	case 1: // message.ping_message
		if wire != proto.WireBytes {
			return true, proto.ErrInternalBadWireType
		}
		msg := new(PingMessage)
		err := b.DecodeMessage(msg)
		m.Message = &Message_PingMessage{msg}
		return true, err
	default:
		return false, nil
	}
}

func _Message_OneofSizer(msg proto.Message) (n int) {
	m := msg.(*Message)
	// message
	switch x := m.Message.(type) {
	case *Message_PingMessage:
		s := proto.Size(x.PingMessage)
		n += 1 // tag and wire
		n += proto.SizeVarint(uint64(s))
		n += s
	case nil:
	default:
		panic(fmt.Sprintf("proto: unexpected type %T in oneof", x))
	}
	return n
}

type PingMessage struct {
	Sequence             uint32   `protobuf:"varint,1,opt,name=sequence,proto3" json:"sequence,omitempty"`
	CommitHash           string   `protobuf:"bytes,2,opt,name=commit_hash,json=commitHash,proto3" json:"commit_hash,omitempty"`
	Rssi                 float32  `protobuf:"fixed32,3,opt,name=rssi,proto3" json:"rssi,omitempty"`
	XXX_NoUnkeyedLiteral struct{} `json:"-"`
	XXX_unrecognized     []byte   `json:"-"`
	XXX_sizecache        int32    `json:"-"`
}

func (m *PingMessage) Reset()         { *m = PingMessage{} }
func (m *PingMessage) String() string { return proto.CompactTextString(m) }
func (*PingMessage) ProtoMessage()    {}
func (*PingMessage) Descriptor() ([]byte, []int) {
	return fileDescriptor_33c57e4bae7b9afd, []int{1}
}

func (m *PingMessage) XXX_Unmarshal(b []byte) error {
	return xxx_messageInfo_PingMessage.Unmarshal(m, b)
}
func (m *PingMessage) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	return xxx_messageInfo_PingMessage.Marshal(b, m, deterministic)
}
func (m *PingMessage) XXX_Merge(src proto.Message) {
	xxx_messageInfo_PingMessage.Merge(m, src)
}
func (m *PingMessage) XXX_Size() int {
	return xxx_messageInfo_PingMessage.Size(m)
}
func (m *PingMessage) XXX_DiscardUnknown() {
	xxx_messageInfo_PingMessage.DiscardUnknown(m)
}

var xxx_messageInfo_PingMessage proto.InternalMessageInfo

func (m *PingMessage) GetSequence() uint32 {
	if m != nil {
		return m.Sequence
	}
	return 0
}

func (m *PingMessage) GetCommitHash() string {
	if m != nil {
		return m.CommitHash
	}
	return ""
}

func (m *PingMessage) GetRssi() float32 {
	if m != nil {
		return m.Rssi
	}
	return 0
}

func init() {
	proto.RegisterType((*Message)(nil), "nbiot_e2e.Message")
	proto.RegisterType((*PingMessage)(nil), "nbiot_e2e.PingMessage")
}

func init() { proto.RegisterFile("message.proto", fileDescriptor_33c57e4bae7b9afd) }

var fileDescriptor_33c57e4bae7b9afd = []byte{
	// 241 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0x4c, 0x8f, 0xbf, 0x6a, 0xc3, 0x30,
	0x10, 0x87, 0x6b, 0xf7, 0x4f, 0xe2, 0x73, 0xb3, 0x68, 0x28, 0x26, 0x93, 0x49, 0xa1, 0x78, 0x89,
	0x05, 0xee, 0xd8, 0xa1, 0xe0, 0x29, 0x4b, 0xa1, 0xf5, 0xd8, 0xc5, 0x48, 0xee, 0x21, 0x0b, 0x62,
	0x49, 0xd5, 0x29, 0x7d, 0x90, 0x3e, 0x71, 0xc1, 0x32, 0x69, 0xb6, 0xfb, 0xdd, 0x7d, 0xf7, 0x71,
	0x07, 0x9b, 0x09, 0x89, 0x84, 0xc2, 0xda, 0x79, 0x1b, 0x2c, 0xcb, 0x8c, 0xd4, 0x36, 0xf4, 0xd8,
	0xe0, 0xf6, 0xd1, 0x08, 0x63, 0x9d, 0xe4, 0x0a, 0x0d, 0x7a, 0x11, 0xac, 0xe7, 0x33, 0xc2, 0x63,
	0x3b, 0xf2, 0xbb, 0x0f, 0x58, 0xbd, 0x45, 0x01, 0x7b, 0x81, 0x7b, 0xa7, 0x8d, 0xea, 0x17, 0x61,
	0x91, 0x94, 0x49, 0x95, 0x37, 0x0f, 0xf5, 0xd9, 0x58, 0xbf, 0x6b, 0xa3, 0x16, 0xfa, 0x70, 0xd5,
	0xe5, 0xee, 0x3f, 0xb6, 0x19, 0xac, 0x96, 0xbd, 0x1d, 0x42, 0x7e, 0x01, 0xb2, 0x2d, 0xac, 0x09,
	0xbf, 0x4f, 0x68, 0x86, 0xa8, 0xdc, 0x74, 0xe7, 0xcc, 0x9e, 0x20, 0x1f, 0xec, 0x34, 0xe9, 0xd0,
	0x8f, 0x82, 0xc6, 0x22, 0x2d, 0x93, 0x2a, 0x6b, 0x6f, 0x7f, 0x5f, 0xd3, 0x75, 0xd5, 0x41, 0x9c,
	0x1c, 0x04, 0x8d, 0x8c, 0xc1, 0x8d, 0x27, 0xd2, 0xc5, 0x75, 0x99, 0x54, 0x69, 0x37, 0xd7, 0x2d,
	0xff, 0xdc, 0x2b, 0x1d, 0xc6, 0x93, 0xac, 0x07, 0x3b, 0xf1, 0x80, 0x47, 0x34, 0xd6, 0x7f, 0x69,
	0xa5, 0x83, 0x38, 0xf2, 0xf9, 0xe6, 0x3d, 0x36, 0xc8, 0x09, 0xfd, 0x0f, 0x7a, 0xee, 0xa4, 0xbc,
	0x9b, 0x3f, 0x7e, 0xfe, 0x0b, 0x00, 0x00, 0xff, 0xff, 0x1f, 0xf3, 0x2c, 0x8c, 0x32, 0x01, 0x00,
	0x00,
}