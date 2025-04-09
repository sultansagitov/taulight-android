package net.result.taulight;

import android.annotation.TargetApi;
import android.os.Build;

import net.result.sandnode.serverclient.SandnodeClient;

import java.util.Optional;

public final class MemberClient {
    public String nickname;
    public final SandnodeClient client;
    public final String link;

    public MemberClient(SandnodeClient client, String link) {
        this.client = client;
        this.link = link;
    }

    @TargetApi(Build.VERSION_CODES.N)
    public Optional<String> nickname() {
        return Optional.ofNullable(nickname);
    }
}
