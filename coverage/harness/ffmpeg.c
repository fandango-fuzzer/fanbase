/* Reads an image with FFmpeg's libraries, as an application would: the format found by probing the file, then every
   frame decoded. Built with the decoders for PPM, XBM and XPM only. Exit 0: it did. 1: FFmpeg said no. */
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <stdio.h>

#define MAX_FRAMES 100

static int fail(const char *what, int code) {
    char message[AV_ERROR_MAX_STRING_SIZE];
    av_strerror(code, message, sizeof message);
    fprintf(stderr, "invalid image: %s: %s\n", what, message);
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    av_log_set_level(AV_LOG_QUIET);

    AVFormatContext *format = NULL;
    int code = avformat_open_input(&format, argv[1], NULL, NULL);
    if (code < 0) return fail("open", code);
    if ((code = avformat_find_stream_info(format, NULL)) < 0) {
        avformat_close_input(&format);
        return fail("stream info", code);
    }
    int index = av_find_best_stream(format, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (index < 0) {
        avformat_close_input(&format);
        return fail("no image", index);
    }
    if ((long long)format->streams[index]->codecpar->width * format->streams[index]->codecpar->height > (1LL << 26)) {
        avformat_close_input(&format);
        fprintf(stderr, "image too large for this reader\n");
        return 1;
    }
    const AVCodec *codec = avcodec_find_decoder(format->streams[index]->codecpar->codec_id);
    AVCodecContext *context = codec ? avcodec_alloc_context3(codec) : NULL;
    if (!context) {
        avformat_close_input(&format);
        return fail("no decoder", AVERROR_DECODER_NOT_FOUND);
    }
    context->max_pixels = 1 << 26; /* a file that asks for more is refused, as an application may */
    int status = 0;
    if ((code = avcodec_parameters_to_context(context, format->streams[index]->codecpar)) < 0 ||
        (code = avcodec_open2(context, codec, NULL)) < 0) {
        status = fail("decoder", code);
    }

    AVPacket *packet = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    int frames = 0;
    while (status == 0 && frames < MAX_FRAMES && (code = av_read_frame(format, packet)) >= 0) {
        if (packet->stream_index == index) {
            code = avcodec_send_packet(context, packet);
            while (code >= 0) {
                code = avcodec_receive_frame(context, frame);
                if (code == 0) frames++;
            }
            if (code != AVERROR(EAGAIN) && code != AVERROR_EOF) status = fail("decode", code);
        }
        av_packet_unref(packet);
    }
    if (status == 0 && frames == 0) status = fail("no frame", AVERROR_INVALIDDATA);
    av_frame_free(&frame);
    av_packet_free(&packet);
    avcodec_free_context(&context);
    avformat_close_input(&format);
    return status;
}
