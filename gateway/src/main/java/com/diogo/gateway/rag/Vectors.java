package com.diogo.gateway.rag;

/** Util: converte float[] no literal aceito pelo pgvector ('[v1,v2,...]'). */
final class Vectors {

    private Vectors() {
    }

    static String toLiteral(float[] v) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < v.length; i++) {
            if (i > 0) sb.append(',');
            sb.append(v[i]);
        }
        return sb.append(']').toString();
    }
}
